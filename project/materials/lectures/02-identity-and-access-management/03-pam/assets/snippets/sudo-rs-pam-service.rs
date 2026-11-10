@@ 41
    let service_name = match launch {
        LaunchType::Login if cfg!(feature = "pam-login") => "sudo-i",
        LaunchType::Login | LaunchType::Shell | LaunchType::Direct => "sudo",
    };
