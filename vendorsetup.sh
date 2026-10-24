git clone https://github.com/raphael-resources/android_device_xiaomi_sm8150-common.git device/xiaomi/sm8150-common
git clone https://github.com/raphael-resources/android_kernel_xiaomi_sm8150.git kernel/xiaomi/sm8150
git clone https://github.com/raphael-resources/android_hardware_xiaomi.git hardware/xiaomi
git clone https://github.com/Lunaris-AOSP/vendor_lunaris-priv_keys.git vendor/lunaris-priv/keys
git clone https://github.com/raphael-resources/device_xiaomi_miuicamera.git -b 16.2 device/xiaomi/miuicamera

echo ""
if [ -c /dev/tty ]; then
    read -p "Building for raphael?: (y/n) [default: n]: " choice < /dev/tty
else
    read -p "Building for raphael?: (y/n) [default: n]: " choice
fi

case "$choice" in
    [yY]*|1)
        echo "Removing existing Dolby..."
        rm -rf packages/apps/LunarisDolby
        echo "Cloning raphael repos for Dolby..."
        git clone https://github.com/oscaro-resources/hardware_dolby.git -b lunaris-dolby hardware/dolby
	git clone https://github.com/raphael-resources/proprietary_vendor_xiaomi_raphael.git vendor/xiaomi/raphael
	git clone https://github.com/raphael-resources/proprietary_vendor_xiaomi_sm8150-common.git vendor/xiaomi/sm8150-common
	git clone https://github.com/raphael-resources/vendor_xiaomi_miuicamera.git -b 17.0 vendor/xiaomi/miuicamera
        ;;
    *)
        echo "Skipping raphael Dolby repo."
        ;;
esac

# Fetch and cherry-pick hardware/interfaces commits
(
    if [ -d "hardware/interfaces/.git" ]; then
        INTERFACES_DIR="hardware/interfaces"
    else
        TOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../../.." && pwd)"
        INTERFACES_DIR="${TOP_DIR}/hardware/interfaces"
    fi

    if [ ! -d "$INTERFACES_DIR/.git" ]; then
        echo "hardware/interfaces repository not found, skipping."
    else
        REMOTE_URL="https://github.com/erg-raphael-5-4/android_hardware_interfaces"
        COMMITS=(
            "13bb4971a749ef28871e1a68efb3ace5e3344dba|camera: device@3.2-impl: Allow returning HFR video buffers per frame"
            "7cfebcb156c9eb2b518e2aa10964702c3a4067ed|camera: common: Optionally advertise a 60 fps high speed preview"
        )

        is_commit_applied() {
            local commit="$1"
            local fallback_subject="$2"

            if git -C "$INTERFACES_DIR" merge-base --is-ancestor "$commit" HEAD 2>/dev/null; then
                return 0
            fi
            if git -C "$INTERFACES_DIR" log --grep="$commit" -n 1 --format="%H" HEAD 2>/dev/null | grep -q .; then
                return 0
            fi
            local subject
            subject=$(git -C "$INTERFACES_DIR" log -1 --format="%s" "$commit" 2>/dev/null)
            [ -z "$subject" ] && subject="$fallback_subject"
            if [ -n "$subject" ] && git -C "$INTERFACES_DIR" log --fixed-strings --grep="$subject" -n 1 --format="%H" HEAD 2>/dev/null | grep -q .; then
                return 0
            fi
            return 1
        }

        FETCH_COMMITS=()
        for item in "${COMMITS[@]}"; do
            commit="${item%%|*}"
            subject="${item#*|}"
            if ! is_commit_applied "$commit" "$subject"; then
                FETCH_COMMITS+=("$commit")
            fi
        done

        if [ ${#FETCH_COMMITS[@]} -gt 0 ]; then
            echo "Fetching hardware/interfaces commits..."
            git -C "$INTERFACES_DIR" fetch "$REMOTE_URL" "${FETCH_COMMITS[@]}"

            for item in "${COMMITS[@]}"; do
                commit="${item%%|*}"
                subject="${item#*|}"
                if is_commit_applied "$commit" "$subject"; then
                    echo "hardware/interfaces: Commit $commit already applied, skipping."
                else
                    echo "hardware/interfaces: Cherry-picking $commit..."
                    if ! git -C "$INTERFACES_DIR" cherry-pick -x --no-edit "$commit"; then
                        echo "hardware/interfaces: Failed to cherry-pick $commit! Aborting cherry-pick."
                        git -C "$INTERFACES_DIR" cherry-pick --abort 2>/dev/null
                    fi
                fi
            done
        else
            echo "hardware/interfaces: Required commits already applied."
        fi
    fi
)

