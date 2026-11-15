<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserE2eeKey extends Model
{
    protected $table = 'user_e2ee_keys';
    protected $fillable = ['user_id', 'identity_key', 'key_version'];
}
