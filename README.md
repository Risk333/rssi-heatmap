# CS-549 Performance Analysis Of Computer Networks
## Project Title: RSSI based contour mapping for optimum router placement

Our Team: Ravi H M (b21317), Vasu Jain (b21233), Vatsal Hariramani (b21234)

Experiment was conducted in IIT MANDI south campus B5 Hostel Ground floor

All the files in parent directory are self-explanatory in names.

Here are the step to execute the .psi script to find the average RSSI in a location.
1. Download the windows OS software from here: https://www.nirsoft.net/utils/wifi_information_view.html (click Download WifiInfoView (64-bit))
2. unzip the downloaded file with name - wifiinfoview-x64
3. move the .psi files to the unzipped folder - wifiinfoview-x64
4. open terminal and move to the wifiinfoview-x64 folder location using ```cd``` command.
5. run this command ```powershell.exe -noprofile -executionpolicy bypass -file .\Find_avgRSSI_perPoint.ps1```

Excepted Folder structure:
wifiinfoview-x64
|
|-> readme.md
|-> WifiInfoView.chm
|-> WifiInfoView.exe
|-> Find_avgRSSI_perPoint.psi