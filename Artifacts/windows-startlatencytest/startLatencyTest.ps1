$SQLServer = "dtlloadtestserver.database.windows.net"
$SQLDBName = "DTLLoadTestDB "
$uid ="ldignan"
$pwd = "adjf@CMK9vldf9a"
$machineName  = $env:COMPUTERNAME
$SqlQuery = "exec RegisterListener '$machineName'"

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; User ID = $uid; Password = $pwd;"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
$SqlCmd.Connection.Open();
$SqlCmd.ExecuteNonQuery();



