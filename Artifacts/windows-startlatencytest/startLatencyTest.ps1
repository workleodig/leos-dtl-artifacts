function getCommand([string] $cmdText)
{
    $SQLServer = "dtlloadtestserver.database.windows.net"
    $SQLDBName = "DTLLoadTestDB "
    $uid ="ldignan"
    $pwd = "adjf@CMK9vldf9a"
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; User ID = $uid; Password = $pwd;"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $cmdText
    $SqlCmd.Connection = $SqlConnection
    $SqlCmd.Connection.Open()
    return $SqlCmd
}

function executeScalar([string] $cmdText)
{
    $sqlCmd = getCommand($cmdText)
    $result = $SqlCmd.ExecuteScalar()
    return $result
}


$machineName  = $env:COMPUTERNAME
$SqlQuery = "exec RegisterListener '$machineName'"
$meh = executeScalar($SqlQuery)

$SqlQuery = "exec GetArgs '$machineName'"
$arguments = executeScalar($SqlQuery)

if(!$arguments -eq '')
{
    #run the latency check
    echo Running with $arguments
    $filePath = '..\..\Diskspd\diskspd.exe'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $filePath    
    $psi.Arguments = $arguments
    $psi.UseShellExecute = false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start()
    $proc.WaitForExit()

    #upload the results
    if($proc.ExitCode -eq 0)
    {
        $output = $proc.StandardOutput.ReadToEnd().Trim();
        echo $output

        $sqlCmd = getCommand("exec UploadResult @machineName, @text, @success")
        $sqlCmd.Parameters.Add("@machineName", [System.Data.SqlDbType]::NVarChar, 40)
        $sqlCmd.Parameters.Add("@text", [System.Data.SqlDbType]::Text)
        $sqlCmd.Parameters.Add("@success", [System.Data.SqlDbType]::Bit)
        $sqlCmd.Parameters["@machineName"].Value = $machineName
        $sqlCmd.Parameters["@text"].Value = $output
        $sqlCmd.Parameters["@success"].Value = 1

        $meh = $sqlCmd.ExecuteScalar();
    }
    else
    {
        $output = $proc.StandardError.ReadToEnd();
        $exitCode = $proc.ExitCode
        $resultText = "Process ended with exit code $exitCode and output $output"
        $SqlQuery = "exec UploadResult '$machineName' '$resultText', 0"
        $meh = executeScalar($SqlQuery)
    }
}
else
{
    echo 'Nothing to run'
}
