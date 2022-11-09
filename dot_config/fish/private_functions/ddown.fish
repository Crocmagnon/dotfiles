function ddown
    #set -l workdir (docker inspect -f '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' (docker ps -q | head -n1))
    set -l compose_file (docker inspect -f '{{ index .Config.Labels "com.docker.compose.project.config_files" }}' (docker ps -q | head -n1))
    docker compose -f "$compose_file" down
end
