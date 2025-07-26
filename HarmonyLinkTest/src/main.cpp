// Copyright (c) 2024 Jordon Brooks
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//   http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <iostream>
#include <chrono>
#include <thread>
#include <atomic>

#include "HarmonyLink.h"

// Include necessary headers for platform-specific functionality
#ifdef BUILD_WINDOWS
#include <conio.h> // For _kbhit() and _getch()
#include <windows.h> // For system("cls")
#else
#include <unistd.h> // For read()
#include <termios.h> // For termios
#include <stdio.h> // For getchar()
#include <fcntl.h> // For F_GETFL, F_SETFL and O_NONBLOCK
#endif

std::atomic<bool> quitFlag(false);

// Function to clear the screen cross-platform
void clearScreen() {
#ifdef _WIN32
    system("cls");
#else
    std::cout << "\x1B[2J\x1B[H";
#endif
}


// Function to check if 'q' or 'Q' is pressed in Windows
void checkForQuit() {
    while (!quitFlag) {
#ifdef BUILD_WINDOWS
        if (_kbhit()) {
            const char c = static_cast<char>(_getch());
            if (c == 'q' || c == 'Q') {
                quitFlag = true;
                break;
            }
        }
#else
        struct termios oldt, newt;
        int ch;
        int oldf;
        
        tcgetattr(STDIN_FILENO, &oldt);
        newt = oldt;
        newt.c_lflag &= ~(ICANON | ECHO);
        tcsetattr(STDIN_FILENO, TCSANOW, &newt);
        oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
        fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
        
        ch = getchar();
        
        tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
        fcntl(STDIN_FILENO, F_SETFL, oldf);
        
        if (ch != EOF) {
            ungetc(ch, stdin);
            if (ch == 'q' || ch == 'Q') {
                quitFlag = true;
                break;
            }
        }
#endif
        // Checks for input every roughly 60 frames
        std::this_thread::sleep_for(std::chrono::milliseconds(16));
    }
}

int main()
{
    std::cout << "Hello, World!\n";

    std::thread inputThread(checkForQuit);

    if (!HL::init())
    {
        std::cout << "Failed to init HarmonyLinkLib\n";
        return 1;
    }

    std::cout << "HarmonyLinkLib successfully initialised!\n";

    /*const bool isWine = HarmonyLinkLib::get_is_wine();
    const char* test = isWine ? "is" : "isn't";

    const HarmonyLinkLib::FOSVerInfo* os_info = HarmonyLinkLib::get_os_version();

    const HarmonyLinkLib::FDevice* device_info = HarmonyLinkLib::get_device_info();

    const HarmonyLinkLib::FCPUInfo* cpu_info = HarmonyLinkLib::get_cpu_info();*/

    // This loop is to test how stable & expensive these functions are
    /*while (!quitFlag)
    {
        // Clear the screen
        clearScreen();

        //std::wcout << "This program " << test << " running under wine.\n";

        /*if (cpu_info)
        {
            cpu_info->print();
        }*/

        /*if (os_info)
        {
            os_info->print();
        }*/

        /*if (device_info)
        {
            wprintf(L"Is SteamDeck: %s\n", device_info->device == HarmonyLinkLib::EDevice::STEAM_DECK ? L"true" : L"false");
        }*/

        // we can't do this before the loop because we need updated values
        /*if (const HarmonyLinkLib::FBattery* battery = HarmonyLinkLib::get_battery_status())
        {
            battery->to_string();
            battery->free();
        }*/

        //const bool is_docked = HarmonyLinkLib::get_is_docked();

        //const char* dock_check_string = is_docked ? "is" : "isn't";

        //wprintf(L"Device %hs docked\n", dock_check_string);

    //    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    //}

    if (inputThread.joinable())
    {
        inputThread.join();
    }

    /*if (os_info)
    {
        os_info->free();
    }*/

    /*if (device_info)
    {
        device_info->free();
    }*/

    /*if (cpu_info)
    {
        cpu_info->free();
    }*/
    
    return 0;
}
