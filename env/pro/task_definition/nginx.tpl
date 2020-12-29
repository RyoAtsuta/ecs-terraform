[
    {
        "name" : "nginx",
        "image" : "nginx:1.14",
        "memoryReservation": 256,
        "cpu": 512,
        "portMappings" : [
            {
                "containerPort" : 80,
                "hostPort" : 80
            }
        ],
        "environment" : [
            {
                "name" : "SAMPLE_VARIABLE",
                "value" : "${sample_variable}"
            }
        ]
    }
]