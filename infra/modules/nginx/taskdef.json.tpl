[
    {
        "name": "${app_name}",
        "image": "${repository_url}:latest",
        "cpu": 0,
        "portMappings": [
            {
                "name": "${app_name}-${app_port}-tcp",
                "containerPort": ${app_port},
                "hostPort": ${app_port},
                "protocol": "tcp",
                "appProtocol": "http"
            }
        ],
        "essential": true,
        "environment": [
            {
                "name": "SERVICE_S3_BUCKET",
                "value": "${bucket_regional_domain_name}"
            },
            {
                "name": "NGINX_PORT",
                "value": "${app_port}"
            }
        ],
        "mountPoints": [
            {
                "sourceVolume": "NGINX-tmp",
                "containerPath": "/tmp",
                "readOnly": false
            },
            {
                "sourceVolume": "NGINX-confd",
                "containerPath": "/etc/nginx/conf.d",
                "readOnly": false
            },
            {
                "sourceVolume": "NGINX-amazon-lib",
                "containerPath": "/var/lib/amazon",
                "readOnly": false
            },
            {
                "sourceVolume": "NGINX-amazon-log",
                "containerPath": "/var/log/amazon",
                "readOnly": false
            }
        ],
        "volumesFrom": [],
        "readonlyRootFilesystem": true,
        "secrets": [],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${ecs_logs}",
                "awslogs-create-group": "true",
                "awslogs-region": "${aws_region_name}",
                "awslogs-stream-prefix": "ecs"
            }
        },
        "systemControls": []
    }
]