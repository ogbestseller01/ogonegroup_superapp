<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;

class RoleHasPermission extends Pivot
{
    protected $table = 'role_has_permissions';

    public $timestamps = false; 
}