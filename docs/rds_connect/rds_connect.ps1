Param($Arg1,$Arg2,$Arg3)
Write-Host $Arg1
Write-Host $Arg2
$ecs_cluster=$Arg1
$ecs_task=$Arg2
$rds_endpoint=$Arg3
$jsondata=aws ecs describe-tasks --cluster $ecs_cluster --task $ecs_task | ConvertFrom-Json
if($?) {
	$ecs_runtimeid=$jsondata.tasks.containers.runtimeId
	$ecs_target="ecs:${ecs_cluster}_${ecs_task}_${ecs_runtimeid}"
	Write-Host $ecs_target
	aws ssm start-session --target $ecs_target --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters portNumber="5432",localPortNumber="5432",host="${RDS_ENDPOINT}"
}

