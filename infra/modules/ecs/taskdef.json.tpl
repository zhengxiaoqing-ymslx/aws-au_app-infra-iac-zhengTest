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
        "environment": [],
        "mountPoints": ${mount_points},
        "volumesFrom": [],
        "readonlyRootFilesystem": ${readonlyRootFilesystem},
        "secrets": [
            {
                "name": "APP_PROFILES_ACTIVE",
                "valueFrom": "${app_profiles_active}"
            },
            {
                "name": "DB_URL",
                "valueFrom": "${db_url}"
            },
            {
                "name": "DB_USERNAME",
                "valueFrom": "${db_username}"
            },
            {
                "name": "DB_PASSWORD",
                "valueFrom": "${db_password}"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${ecs_logs}",
                "awslogs-create-group": "true",
                "awslogs-region": "${aws_region_name}",
                "awslogs-stream-prefix": "ecs"
            }
        },
        "healthCheck": {
            "command": [
                "${healthcheck_command}",
                "${healthcheck_param}"
            ],
            "interval": 60,
            "timeout": 5,
            "retries": 3
        },
        "systemControls": []
    }
]