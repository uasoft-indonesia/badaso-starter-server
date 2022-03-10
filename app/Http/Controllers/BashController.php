<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class BashController extends Controller
{
    public function starterZip()
    {
        $path_stater_zip = base_path(".badaso-starter/starter.zip");
        return response(file_get_contents($path_stater_zip), 200, [
            'Content-Type' => 'application/zip',
        ]);
    }

    public function createProject(Request $request, $project_name)
    {
        $laravel_version = $request->get('laravel-version', '8.0');
        $badaso_version = $request->get('badaso-version', '2.0');

        $bash = file_get_contents(base_path(".badaso-starter/starter.stub"));
        $bash = str_replace([
            "{{laravel-version}}",
            "{{project-name}}",
            "{{badaso-version}}",
            "{{app_url}}"
        ], [
            $laravel_version,
            $project_name,
            $badaso_version,
            env('APP_URL', 'http://localhost:8000')
        ], $bash);

        return response($bash, 200, [
            'Content-Type' => 'text/plain'
        ]);
    }
}
