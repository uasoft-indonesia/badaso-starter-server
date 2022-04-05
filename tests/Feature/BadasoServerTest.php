<?php

namespace Tests\Feature;

use Tests\TestCase;

class BadasoServerTest extends TestCase
{
    public function test_the_homepage_redirects_to_the_badaso_docs()
    {
        $this->get('/')->assertRedirect('https://badaso-docs.uatech.co.id');
    }
}