<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::redirect('/', 'https://badaso-docs.uatech.co.id', 302);

Route::get('/{name}', function (Request $request, $name) {
    try {
        Validator::validate(['name' => $name], ['name' => 'string|alpha_dash']);
    } catch (ValidationException $e) {
        return response('Invalid site name. Please only use alpha-numeric characters, dashes, and underscores.', 400);
    }

    $account_name = $request->query('account_name', 'Admin');
    $account_username = $request->query('account_username', "admin");
    $account_password = $request->query('account_password', "badaso");
    $account_email = $request->query('account_email', "admin@admin.com");
    $devcontainer = $request->has('devcontainer') ? '--devcontainer' : '';

    $server_url = env('APP_URL');

    $script = str_replace(
        ['{{ name }}', '{{ account_name }}', '{{ account_username }}', '{{ account_email }}', '{{ account_password }}', '{{ devcontainer }}', '{{ server_url }}'],
        [$name, $account_name, $account_username, $account_email, $account_password, $devcontainer, $server_url],
        file_get_contents(resource_path('scripts/badaso.sh'))
    );

    return response($script, 200, ['Content-Type' => 'text/plain']);
});
