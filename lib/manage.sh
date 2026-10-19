# shellcheck shell=bash
# Works In All Things Kiosk: management from Rock, with the Kiosk Manager plugin. Sourced by the kiosk command.
#
# The kiosk asks Rock; Rock never connects to the kiosk. Once a minute kiosk-heartbeat.timer runs "kiosk heartbeat",
# which sends the computer's health to Rock and gets back its settings (when they changed) and any actions. Rock can
# only send the settings and actions listed here, and every value goes through the same checks as the kiosk
# command. Nothing from Rock is ever run as a command.

MANAGER_CONF=$CONFIG_DIR/manager.conf
MANAGER_STATE=$CONFIG_DIR/manager-state
MANAGER_API=api/v2/plugins/com.worksinallthings/kioskmanager
# Present while the screen has been turned off by hand or by Rock, so a heartbeat can tell that from a crash.
SCREEN_OFF_FLAG=/run/kiosk-screen-off
LOCK_FILE=/run/kiosk.lock
# Set when an action from Rock asked for a reboot, which happens once the other actions are done.
REBOOT_WANTED=no

# Locking -----------------------------------------------------------------------------------------------------

# Takes the kiosk lock, so the agent and someone at the keyboard don't change settings at the same time. The lock
# is held until the command ends; commands it starts (such as "kiosk update") see KIOSK_LOCKED and don't wait.
take_lock() {
    local wait=${1:-30}
    [[ -z ${KIOSK_LOCKED:-} ]] || return 0
    exec 9>"$LOCK_FILE"
    flock -w "$wait" 9 || return 1
    export KIOSK_LOCKED=yes
}

# Managed state -----------------------------------------------------------------------------------------------

# Prints a setting from manager.conf.
get_manager() {
    [[ -r $MANAGER_CONF ]] || return 0
    (
        # shellcheck source=/dev/null
        . "$MANAGER_CONF"
        printf '%s' "${!1:-}"
    )
}

# True when this kiosk is managed by Rock and its token still works.
is_managed() {
    [[ -n $(get_manager TOKEN) && ! -e $MANAGER_STATE/revoked ]]
}

# Stops with a message when a setting is managed by Rock, so it's changed there instead.
refuse_if_managed() {
    is_managed || return 0
    die "This kiosk is managed by Rock ($(get_manager ROCK_ADDRESS)). Change its $1 on the kiosk's page in Rock, or stop managing it with: sudo kiosk unmanage"
}

# Prints a file from the managed state folder, or nothing.
get_state() {
    [[ -r $MANAGER_STATE/$1 ]] && cat "$MANAGER_STATE/$1"
    return 0
}

# Saves a value in the managed state folder.
set_state() {
    mkdir -p "$MANAGER_STATE"
    chmod 700 "$MANAGER_STATE"
    printf '%s' "$2" >"$MANAGER_STATE/$1"
}

# Talking to Rock ---------------------------------------------------------------------------------------------

# Sends a JSON body to one of Kiosk Manager's endpoints. Sets RESPONSE_STATUS (000 when Rock couldn't be reached)
# and RESPONSE_BODY. The body goes on standard input, so the token never shows in the process list.
rock_post() {
    local address=$1 endpoint=$2 body=$3 allow_http=$4 output
    local -a protocols=(--proto "=https" --proto-redir "=https")
    [[ $allow_http == yes ]] && protocols=(--proto "=https,http" --proto-redir "=https,http")
    if output=$(printf '%s' "$body" | curl -sS --max-time 20 "${protocols[@]}" -X POST \
        -H 'Content-Type: application/json' -H 'Accept: application/json' \
        --data-binary @- -w '\n%{http_code}' "$address/$MANAGER_API/$endpoint" 2>&1); then
        RESPONSE_STATUS=${output##*$'\n'}
        RESPONSE_BODY=${output%$'\n'*}
    else
        # curl still writes the status code (000) after its error message.
        RESPONSE_STATUS=000
        RESPONSE_BODY=${output%$'\n'000}
    fi
}

# Prints Rock's message from a refused request, or a general one.
rock_message() {
    local message
    message=$(jq -r '.message // empty' <<<"$RESPONSE_BODY" 2>/dev/null || true)
    if [[ -n $message ]]; then
        printf '%s' "$message"
    elif [[ $RESPONSE_STATUS == 000 ]]; then
        printf "Couldn't reach Rock: %s" "${RESPONSE_BODY:0:200}"
    elif [[ $RESPONSE_STATUS == bad-answer ]]; then
        printf '%s' "$RESPONSE_BODY"
    elif [[ $RESPONSE_STATUS == 404 ]]; then
        printf 'Rock answered 404. Check the address, and that the Kiosk Manager plugin is installed.'
    else
        printf 'Rock answered %s.' "$RESPONSE_STATUS"
    fi
}

# Prints a whole number for JSON, or null.
json_number() {
    [[ $1 =~ ^-?[0-9]+$ ]] && printf '%s' "$1" || printf 'null'
}

# Checks the Rock address a kiosk is managed from.
is_rock_address() {
    [[ $1 =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/[^[:space:]]*)?$ ]]
}

# Checks an action's unique identifier.
is_guid() {
    [[ $1 =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$ ]]
}

# Health ------------------------------------------------------------------------------------------------------

# Prints the browser and its version, such as "Chromium 140.0.7339.80".
browser_name() {
    local browser version
    browser=$(get_setting BROWSER)
    if [[ $browser == flatpak ]]; then
        version=$(flatpak info "$FLATPAK_APP" 2>/dev/null | awk -F': *' '/^ *Version:/ { print $2; exit }' || true)
        printf 'Chromium %s (Flathub)' "${version:-}"
    elif [[ -n $browser && -x $browser ]]; then
        timeout 5 "$browser" --version 2>/dev/null | head -n 1 || printf 'Chromium'
    fi
}

# Prints the highest temperature the hardware reports, in whole degrees Celsius, or nothing.
temperature() {
    local zone value highest=""
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        [[ -r $zone ]] || continue
        value=$(cat "$zone" 2>/dev/null || true)
        [[ $value =~ ^[0-9]+$ ]] || continue
        value=$((value / 1000))
        [[ -z $highest || $value -gt $highest ]] && highest=$value
    done
    printf '%s' "$highest"
}

# Prints the distribution and version, such as "Ubuntu 26.04 LTS".
os_name() {
    (
        # shellcheck source=/dev/null
        . /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-}"
    ) || true
}

# True while the screen is meant to be off: turned off by hand or by Rock, or in its daily off hours.
is_screen_off() {
    [[ -e $SCREEN_OFF_FLAG ]] || screen_should_be_off
}

# Prints the heartbeat's JSON body: the token, the computer's health and the results of the actions done since
# the last heartbeat.
heartbeat_body() {
    local token=$1 uptime disk memory_total memory_available browser_running=false screen_on=true problem
    uptime=$(cut -d. -f1 /proc/uptime 2>/dev/null || true)
    disk=$(df -Pm / 2>/dev/null | awk 'NR == 2 { print $4 }' || true)
    memory_total=$(awk '/^MemTotal:/ { print int($2 / 1024) }' /proc/meminfo 2>/dev/null || true)
    memory_available=$(awk '/^MemAvailable:/ { print int($2 / 1024) }' /proc/meminfo 2>/dev/null || true)
    systemctl is-active --quiet kiosk.service 2>/dev/null && browser_running=true
    is_screen_off && screen_on=false
    problem=$(journalctl -u kiosk.service -p err --since -1h -n 1 -o cat --no-pager 2>/dev/null | tail -n 1 || true)
    local results
    # One result per line. A line cut short (by a power cut, say) is skipped rather than spoiling the heartbeat.
    results=$(jq -cn '[inputs]' "$MANAGER_STATE/results" 2>/dev/null ||
        jq -Rcn '[inputs | fromjson? | objects]' "$MANAGER_STATE/results" 2>/dev/null || echo '[]')
    jq -n \
        --arg token "$token" \
        --arg kioskVersion "$KIOSK_VERSION" \
        --arg hostname "$(hostname 2>/dev/null || true)" \
        --arg localIpAddresses "$(hostname -I 2>/dev/null | xargs || true)" \
        --arg osName "$(os_name)" \
        --arg browserName "$(browser_name)" \
        --argjson uptimeSeconds "$(json_number "$uptime")" \
        --argjson diskFreeMegabytes "$(json_number "$disk")" \
        --argjson memoryAvailableMegabytes "$(json_number "$memory_available")" \
        --argjson memoryTotalMegabytes "$(json_number "$memory_total")" \
        --argjson temperatureCelsius "$(json_number "$(temperature)")" \
        --argjson isBrowserRunning "$browser_running" \
        --argjson isScreenOn "$screen_on" \
        --argjson appliedSettingsVersion "$(json_number "$(get_state applied-version)")" \
        --arg settingsProblem "$(get_state settings-problem)" \
        --arg lastProblem "${problem:0:500}" \
        --argjson actionResults "$results" \
        '{token: $token, kioskVersion: $kioskVersion, hostname: $hostname, localIpAddresses: $localIpAddresses,
          osName: $osName, browserName: $browserName, uptimeSeconds: $uptimeSeconds,
          diskFreeMegabytes: $diskFreeMegabytes, memoryAvailableMegabytes: $memoryAvailableMegabytes,
          memoryTotalMegabytes: $memoryTotalMegabytes, temperatureCelsius: $temperatureCelsius,
          isBrowserRunning: $isBrowserRunning, isScreenOn: $isScreenOn,
          appliedSettingsVersion: $appliedSettingsVersion, settingsProblem: $settingsProblem,
          lastProblem: $lastProblem, actionResults: $actionResults}'
}

# Settings and actions from Rock ------------------------------------------------------------------------------

# Prints one field of Rock's answer as text ("" for a missing or null field).
answer_field() {
    jq -r "$1 // \"\" | tostring" <<<"$RESPONSE_BODY" 2>/dev/null || true
}

# Applies the settings in Rock's answer, each one checked first. A value that fails its check isn't applied, and
# the problem is reported in the next heartbeat. With "no-restart" (during install) nothing is restarted.
apply_settings() {
    local mode=${1:-} version url timezone rotation resolution screen_off screen_on restart_time
    local -a problems=()
    local restart_browser=no current_timezone
    version=$(answer_field .settings.version)
    [[ $version =~ ^[0-9]+$ ]] || return 0
    url=$(answer_field .settings.url)
    timezone=$(answer_field .settings.timeZone)
    rotation=$(answer_field .settings.rotation)
    resolution=$(answer_field .settings.resolution)
    screen_off=$(answer_field .settings.screenOffTime)
    screen_on=$(answer_field .settings.screenOnTime)
    restart_time=$(answer_field .settings.restartTime)

    if is_url "$url"; then
        [[ $url == "$(get_setting URL)" ]] || { set_setting URL "$url"; restart_browser=yes; }
    else
        problems+=("the address isn't a web address")
    fi
    if is_timezone "$timezone"; then
        current_timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || true)
        if [[ $timezone != "$current_timezone" ]] && ! timedatectl set-timezone "$timezone" 2>/dev/null; then
            problems+=("the time zone couldn't be set")
        fi
    else
        problems+=("this computer doesn't know the time zone $timezone")
    fi
    if is_rotation "$rotation"; then
        [[ $rotation == "$(get_setting ROTATION)" ]] || { set_setting ROTATION "$rotation"; restart_browser=yes; }
    else
        problems+=("the rotation must be 0, 90, 180 or 270")
    fi
    if [[ -z $resolution ]] || is_resolution "$resolution"; then
        [[ $resolution == "$(get_setting RESOLUTION)" ]] || { set_setting RESOLUTION "$resolution"; restart_browser=yes; }
    else
        problems+=("the resolution isn't like 1920x1080")
    fi
    if { [[ -z $screen_off && -z $screen_on ]] || { is_time "$screen_off" && is_time "$screen_on"; }; }; then
        set_setting SCREEN_OFF "$screen_off"
        set_setting SCREEN_ON "$screen_on"
    else
        problems+=("the screen times must both be 24-hour times")
    fi
    if is_time_or_blank "$restart_time"; then
        set_setting RESTART_TIME "$restart_time"
    else
        problems+=("the restart time isn't a 24-hour time")
    fi

    write_timers
    set_state applied-version "$version"
    if [[ ${#problems[@]} -gt 0 ]]; then
        local problem_text
        problem_text=$(printf '%s; ' "${problems[@]}")
        problem_text=${problem_text%; }
        set_state settings-problem "$problem_text"
        echo "Rock's settings version $version: $problem_text" >&2
    else
        set_state settings-problem ""
        echo "Applied Rock's settings version $version."
    fi
    if [[ $restart_browser == yes && $mode != no-restart ]]; then
        systemctl restart kiosk.service 2>/dev/null || true
    fi
}

# Prints the last line of a command's output without its colors, for an action's result message.
plain_text() {
    local text
    text=$(tail -n 1 <<<"$1" | sed 's/\x1b\[[0-9;]*m//g; s/^==> //; s/^Error: //')
    printf '%s' "${text:-No message.}"
}

# Records an action's result, to send with the next heartbeat.
record_result() {
    local guid=$1 success=$2 message=$3
    mkdir -p "$MANAGER_STATE"
    jq -nc --arg guid "$guid" --argjson isSuccess "$success" --arg message "${message:0:500}" \
        '{guid: $guid, isSuccess: $isSuccess, message: $message}' >>"$MANAGER_STATE/results"
}

# Does the actions in Rock's answer, each matched against a fixed list. Sets REBOOT_WANTED when one asked for a
# reboot, which happens after the others, once its result is saved.
do_actions() {
    local guid type output
    REBOOT_WANTED=no
    while read -r guid type; do
        [[ -n $guid ]] || continue
        is_guid "$guid" || continue
        case $type in
            restart-browser)
                if systemctl restart kiosk.service 2>/dev/null; then
                    record_result "$guid" true "The browser restarted."
                else
                    record_result "$guid" false "The browser couldn't be restarted."
                fi
                ;;
            screen-off)
                if output=$(cmd_screen off 2>&1); then
                    record_result "$guid" true "The screen is off."
                else
                    record_result "$guid" false "$(plain_text "$output")"
                fi
                ;;
            screen-on)
                if output=$(cmd_screen on 2>&1); then
                    record_result "$guid" true "The screen is on."
                else
                    record_result "$guid" false "$(plain_text "$output")"
                fi
                ;;
            update)
                if output=$(cmd_update 2>&1); then
                    record_result "$guid" true "$(plain_text "$output")"
                else
                    record_result "$guid" false "$(plain_text "$output")"
                fi
                ;;
            reboot)
                record_result "$guid" true "The computer restarted."
                REBOOT_WANTED=yes
                ;;
            *)
                record_result "$guid" false "This version of Kiosk doesn't know the action '$type'."
                ;;
        esac
    done < <(jq -r '.actions[]? | "\(.guid // "") \(.type // "")"' <<<"$RESPONSE_BODY" 2>/dev/null || true)
}

# Sends one heartbeat and handles the answer. Returns 0 when Rock answered, so the results it got can be cleared.
send_heartbeat() {
    local mode=${1:-} address token allow_http body sent_results
    address=$(get_manager ROCK_ADDRESS)
    token=$(get_manager TOKEN)
    allow_http=$(get_manager ALLOW_HTTP)
    sent_results=$(get_state results)
    body=$(heartbeat_body "$token")
    rock_post "$address" heartbeat "$body" "$allow_http"

    # Only an answer from Kiosk Manager itself counts: a captive portal or proxy can answer 200 or 401 too.
    if [[ $RESPONSE_STATUS == 200 ]] && ! jq -e '.heartbeatSeconds | numbers' >/dev/null 2>&1 <<<"$RESPONSE_BODY"; then
        RESPONSE_STATUS=bad-answer
        RESPONSE_BODY="Rock's answer wasn't from Kiosk Manager. Check the Rock address."
    elif [[ $RESPONSE_STATUS == 401 ]] && ! jq -e '.message | strings' >/dev/null 2>&1 <<<"$RESPONSE_BODY"; then
        RESPONSE_STATUS=bad-answer
        RESPONSE_BODY="Something between this computer and Rock refused the heartbeat (401). Check the Rock address."
    fi

    case $RESPONSE_STATUS in
        200)
            # The results just sent are cleared; any recorded while this ran stay for the next heartbeat.
            if [[ $(get_state results) == "$sent_results" ]]; then
                set_state results ""
            fi
            set_state last-heartbeat "$(date -Is)"
            set_state kiosk-name "$(answer_field .kioskName)"
            set_state last-error ""
            apply_settings "$mode"
            [[ $mode == no-restart ]] || do_actions
            return 0
            ;;
        401)
            set_state revoked "$(rock_message)"
            echo "Rock says this computer is no longer linked to a kiosk: $(rock_message)" >&2
            echo "It keeps showing what it shows. To link it again: sudo kiosk manage <rock address> <new code>" >&2
            systemctl disable --now kiosk-heartbeat.timer >/dev/null 2>&1 || true
            return 1
            ;;
        *)
            # Rock or the network is down: carry on with the current settings and try again next time. Only log
            # when the problem changes, so the log isn't filled every minute.
            local message
            message=$(rock_message)
            [[ $message == "$(get_state last-error)" ]] || echo "Heartbeat failed: $message" >&2
            set_state last-error "$message"
            return 1
            ;;
    esac
}

# Commands ----------------------------------------------------------------------------------------------------

# Sends a heartbeat to Rock (run every minute by kiosk-heartbeat.timer). When actions were done, a second
# heartbeat reports their results straight away.
cmd_heartbeat() {
    require_root heartbeat
    is_managed || exit 0
    take_lock 5 || exit 0
    send_heartbeat "" || return 0
    if [[ -n $(get_state results) && $REBOOT_WANTED != yes ]]; then
        send_heartbeat "" || true
    fi
    if [[ $REBOOT_WANTED == yes ]]; then
        echo "Rebooting, as asked from Rock."
        systemctl reboot
    fi
}

# Links this computer to its kiosk in Rock with the enrollment code shown on the kiosk's page, then gets its
# settings. Used by "kiosk manage" and by "kiosk install --manage".
manage_enroll() {
    local address=${1%/} code=$2 allow_http=$3 body token name
    is_rock_address "$address" || die "The Rock address must be like https://rock.example.org"
    if [[ $address == http://* && $allow_http != yes ]]; then
        die "The Rock address is http://, so this computer's token would cross the network unencrypted. Use https://, or add --allow-http (for a test server)."
    fi
    [[ $code =~ ^[A-Za-z0-9-]{10,20}$ ]] || die "The code must be like ABCDE-23456 (it's on the kiosk's page in Rock)."
    command -v jq >/dev/null 2>&1 || die "jq is needed. Install it, or run the Kiosk installer again."

    info "Linking this computer to Rock ($address)"
    body=$(jq -n --arg code "$code" --arg hostname "$(hostname 2>/dev/null || true)" --arg kioskVersion "$KIOSK_VERSION" \
        '{code: $code, hostname: $hostname, kioskVersion: $kioskVersion}')
    rock_post "$address" enroll "$body" "$allow_http"
    [[ $RESPONSE_STATUS == 200 ]] || die "Rock didn't accept the code: $(rock_message)"
    token=$(answer_field .token)
    name=$(answer_field .kioskName)
    [[ $token =~ ^[A-Za-z0-9_-]{20,100}$ ]] || die "Rock's answer didn't include a token."

    mkdir -p "$CONFIG_DIR"
    rm -rf "$MANAGER_STATE"
    (
        umask 077
        {
            echo "# Works In All Things Kiosk: managed by Rock. Written by \"kiosk manage\"; keep it private."
            printf 'ROCK_ADDRESS=%q\n' "$address"
            printf 'TOKEN=%q\n' "$token"
            printf 'ALLOW_HTTP=%q\n' "${allow_http:-no}"
        } >"$MANAGER_CONF"
    )
    chmod 600 "$MANAGER_CONF"
    set_state kiosk-name "$name"
    set_state results ""
    info "Linked to the kiosk \"$name\" in Rock."
}

# Turns on the heartbeat timer.
enable_heartbeat() {
    systemctl daemon-reload
    systemctl enable --now kiosk-heartbeat.timer >/dev/null
}

# "kiosk manage <rock address> <code> [--allow-http]": links an installed kiosk to Rock, gets its settings and
# turns on the heartbeat.
cmd_manage() {
    local address="" code="" allow_http=no
    while [[ $# -gt 0 ]]; do
        case $1 in
            --allow-http) allow_http=yes; shift ;;
            -*) die "Unknown option: $1 (see: kiosk help)" ;;
            *)
                if [[ -z $address ]]; then address=$1; elif [[ -z $code ]]; then code=$1; else die "Use: sudo kiosk manage <rock address> <code>"; fi
                shift
                ;;
        esac
    done
    [[ -n $address && -n $code ]] || die "Use: sudo kiosk manage <rock address> <code> (both are on the kiosk's page in Rock)"
    require_root manage
    require_installed
    take_lock || die "Another kiosk command is running. Try again in a minute."
    if is_managed && [[ $(get_manager ROCK_ADDRESS) != "${address%/}" ]]; then
        confirm "This kiosk is managed by $(get_manager ROCK_ADDRESS). Switch it to ${address%/}?" n || die "Nothing was changed."
    fi
    manage_enroll "$address" "$code" "$allow_http"
    send_heartbeat "" || die "Linked, but the first heartbeat failed: $(rock_message)"
    enable_heartbeat
    info "Rock manages this kiosk now. Change its settings on its page in Rock."
}

# "kiosk unmanage": stops Rock managing this kiosk. Its settings stay as they are, and the kiosk command can change
# them again.
cmd_unmanage() {
    require_root unmanage
    [[ -e $MANAGER_CONF ]] || { info "This kiosk isn't managed by Rock."; return 0; }
    take_lock || die "Another kiosk command is running. Try again in a minute."
    systemctl disable --now kiosk-heartbeat.timer >/dev/null 2>&1 || true
    rm -rf "$MANAGER_CONF" "$MANAGER_STATE"
    info "Rock no longer manages this kiosk. Its settings are kept; change them with the kiosk command."
    echo "To remove it from Rock too, remove the kiosk on its page in Rock."
}

# Prints the management lines of "kiosk status".
manage_status() {
    [[ -e $MANAGER_CONF ]] || return 0
    local last
    if [[ -e $MANAGER_STATE/revoked ]]; then
        printf '  %-18s %s\n' "Managed by Rock:" "no longer ($(get_state revoked))"
        return 0
    fi
    last=$(get_state last-heartbeat)
    printf '  %-18s %s\n' "Managed by Rock:" "$(get_manager ROCK_ADDRESS), as \"$(get_state kiosk-name)\""
    printf '  %-18s %s\n' "Last heartbeat:" "${last:-not yet}"
    [[ -z $(get_state last-error) ]] || printf '  %-18s %s\n' "Heartbeat problem:" "$(get_state last-error)"
    [[ -z $(get_state settings-problem) ]] || printf '  %-18s %s\n' "Settings problem:" "$(get_state settings-problem)"
}
