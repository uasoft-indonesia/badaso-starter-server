<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use ZipArchive;

class BashController extends Controller
{
    public function starterZip()
    {
        $path_stater_zip = base_path(".badaso-starter/starter.zip");
        return response(file_get_contents($path_stater_zip), 200, [
            'Content-Type' => 'application/zip',
        ]);
    }

    private function folderToZip($folder, &$zipFile, $exclusiveLength)
    {
        $handle = opendir($folder);
        while (false !== $f = readdir($handle)) {
            if ($f != '.' && $f != '..') {
                $filePath = "$folder/$f";
                // Remove prefix from file path before add to zip.
                $localPath = substr($filePath, $exclusiveLength);
                if (is_file($filePath)) {
                    $zipFile->addFile($filePath, $localPath);
                } elseif (is_dir($filePath)) {
                    // Add sub-directory.
                    $zipFile->addEmptyDir($localPath);
                    $this->folderToZip($filePath, $zipFile, $exclusiveLength);
                }
            }
        }
        closedir($handle);
    }

    public function createProject(Request $request, $project_name)
    {
        $laravel_version = $request->get('laravel-version', '8.0');
        $badaso_version = $request->get('badaso-version', '2.0');

        $bash_stub = base_path(".badaso-starter/starter.stub");

        $bash_stub = base_path(".badaso-starter/starter.stub");
        $bash = file_get_contents($bash_stub);
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
