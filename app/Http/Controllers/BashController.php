<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use ZipArchive;

class BashController extends Controller
{

    public function createProject(Request $request, $project_name)
    {
        $laravel_version = $request->get('laravel-version', '8.0');
        $badaso_version = $request->get('badaso-version', '2.0');

        $bash_stub = base_path("stubs/starter.stub");
        $bash = file_get_contents($bash_stub);
        $bash = str_replace([
            "{{laravel-version}}",
            "{{project-name}}",
            "{{badaso-version}}",
            "{{badaso-starter-url}}"
        ], [
            $laravel_version,
            $project_name,
            $badaso_version,
            asset("badaso-starter"),
        ], $bash);

        return response($bash, 200, [
            'Content-Type' => 'text/plain'
        ]);
    }


    public function createDockerCompose(Request $request, $project_name){
        $bash_stub = base_path("stubs/docker-compose.stub");
        $bash = file_get_contents($bash_stub);

        $bash = str_replace("{{project-name}}", $project_name, $bash);

        return response($bash, 200, [
            'Content-Type' => 'text/plain'
        ]);
    }

    public function createEnvExampleDocker(Request $request, $project_name){
        $bash_stub = base_path("stubs/env.example.docker.stub");
        $bash = file_get_contents($bash_stub);

        $project_name = str_replace(["-", " "], "", $project_name);
        $bash = str_replace("{{project-name}}", $project_name, $bash);

        return response($bash, 200, [
            'Content-Type' => 'text/plain'
        ]);
    }
}
