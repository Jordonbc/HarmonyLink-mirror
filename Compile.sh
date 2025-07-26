#!/usr/bin/env bash
set -euo pipefail          # strict-mode
# set -x                   # ← uncomment for full trace
IFS=$'\n\t'

# ── Colour codes ───────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
GRAY='\033[1;30m'
NC='\033[0m'

# ── Error-reporting helper ─────────────────────────────────────────────────────
error_trap () {
    local ec=$?
    echo -e "${RED}Error: “${BASH_COMMAND}” failed (exit $ec) at line $LINENO.${NC}"
}
trap error_trap ERR

# ── Ensure ‘dialog’ is installed ───────────────────────────────────────────────
if ! command -v dialog &> /dev/null; then
    echo "dialog could not be found. Please install it to use this script."
    exit 1
fi

# ── Helper: add compiler to checklist if present ───────────────────────────────
check_compiler() {
    if command -v "$1" &> /dev/null; then
        COMPILER_OPTIONS+=("$2" "$3" "$4")   # tag  description  default-state
    fi
}

# ── Build checklist entries ────────────────────────────────────────────────────
COMPILER_OPTIONS=()
check_compiler g++          "1" "g++ (default)" "on"
check_compiler clang++      "2" "clang++"       "off"
check_compiler clang++-15   "3" "clang++-15"    "off"
check_compiler clang++-16   "4" "clang++-16"    "off"
check_compiler clang++-17   "5" "clang++-17"    "off"

if [ "${#COMPILER_OPTIONS[@]}" -eq 0 ]; then
    dialog --msgbox "No compilers found. Please install one first." 8 45
    exit 1
fi

list_rows=$(( ${#COMPILER_OPTIONS[@]} / 3 ))

# ── Select compilers ───────────────────────────────────────────────────────────
compiler_choices=$(
    dialog --colors --title "\Zb\Z5Select Compiler\Zn" \
           --checklist "\nChoose one or more compilers:" \
           15 60 "$list_rows" \
           "${COMPILER_OPTIONS[@]}" \
           3>&1 1>&2 2>&3
)

C_COMPILERS=()  CXX_COMPILERS=()
for choice in $compiler_choices; do
    case "$choice" in
        1) C_COMPILERS+=("gcc")       ; CXX_COMPILERS+=("g++")        ;;
        2) C_COMPILERS+=("clang")     ; CXX_COMPILERS+=("clang++")    ;;
        3) C_COMPILERS+=("clang-15")  ; CXX_COMPILERS+=("clang++-15") ;;
        4) C_COMPILERS+=("clang-16")  ; CXX_COMPILERS+=("clang++-16") ;;
        5) C_COMPILERS+=("clang-17")  ; CXX_COMPILERS+=("clang++-17") ;;
    esac
done

if [ "${#C_COMPILERS[@]}" -eq 0 ]; then
    dialog --msgbox "No compilers selected – aborting." 8 40
    exit 1
fi

# ── Display selection ──────────────────────────────────────────────────────────
msg=$'Chosen compilers:\n'
for i in "${!C_COMPILERS[@]}"; do
    msg+=$'C: '"${C_COMPILERS[$i]}"$'\tC++: '"${CXX_COMPILERS[$i]}"$'\n'
done
dialog --colors --msgbox "\Zb\Z5${msg}\Zn" 15 60

# ── Build type ─────────────────────────────────────────────────────────────────
build_choice=$(dialog --colors --title "\Zb\Z5Select Build Type\Zn" \
                      --menu "\nChoose a build type:" 10 40 2 \
                      1 "Release (default)" \
                      2 "Debug" 3>&1 1>&2 2>&3)

BUILD_TYPE="Release"
[ "$build_choice" = "2" ] && BUILD_TYPE="Debug"

if dialog --colors --defaultno --title "\Zb\Z5Clean Before Build?\Zn" \
         --yesno "\nClean Rust and CMake artifacts before building?" 8 55
then
    echo -e "${GRAY}>> Cleaning Rust artifacts (cargo clean)…${NC}"
    cargo clean
    if [ -d linuxbuild ]; then
        echo -e "${GRAY}>> Removing linuxbuild/ directory…${NC}"
        rm -r linuxbuild          # no -f
    fi
    echo -e "${GREEN}Clean complete.${NC}"
else
    echo -e "${GRAY}>> Skipping clean step.${NC}"
fi

# ── Build Rust crate ───────────────────────────────────────────────────────────
echo -e "${GRAY}>> Building Rust crate in ${BUILD_TYPE} mode…${NC}"
if [ "$BUILD_TYPE" = "Release" ]; then
    cargo build --release
else
    cargo build
fi
echo -e "${GREEN}Rust build completed.${NC}"

# ── Per-compiler CMake builds ──────────────────────────────────────────────────
mkdir -p linuxbuild
for i in "${!C_COMPILERS[@]}"; do
    C_COMP=${C_COMPILERS[$i]}
    CXX_COMP=${CXX_COMPILERS[$i]}
    build_dir="linuxbuild/${C_COMP}"

    echo -e "${GRAY}>> Configuring with C=${C_COMP}, C++=${CXX_COMP}${NC}"
    cmake -B "$build_dir" \
          -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
          -DCMAKE_C_COMPILER="$C_COMP" \
          -DCMAKE_CXX_COMPILER="$CXX_COMP"

    echo -e "${GRAY}>> Building ${build_dir}…${NC}"
    cmake --build "$build_dir" -j"$(nproc)"
    echo -e "${GREEN}Build with ${CXX_COMP} finished.${NC}"
done

dialog --colors --msgbox "\Zb\Z5Build(s) completed successfully!\Zn" 8 45
