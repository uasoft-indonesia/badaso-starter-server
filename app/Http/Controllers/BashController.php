<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class BashController extends Controller
{
    public function starterZip(){
        $path_stater_zip = base_path(".badaso-starter/starter.zip");
        return response(file_get_contents($path_stater_zip), 200, [
            'Content-Type' => 'application/zip',
        ]);
    }
}
