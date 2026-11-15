<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;

class EncryptPlaintextNidaCommand extends Command
{
    protected $signature   = 'technicians:encrypt-nida';
    protected $description = 'Encrypt any plaintext NIDA values stored in technicians.nida';

    public function handle(): int
    {
        $rows = DB::table('technicians')->select('id', 'nida')->whereNotNull('nida')->get();
        $encrypted = $skipped = 0;

        foreach ($rows as $row) {
            try {
                Crypt::decryptString($row->nida);
                $skipped++;
                continue;
            } catch (\Illuminate\Contracts\Encryption\DecryptException) {
                // plaintext — encrypt now
            }

            DB::table('technicians')->where('id', $row->id)->update([
                'nida'      => Crypt::encryptString($row->nida),
                'nida_hash' => hash('sha256', trim((string) $row->nida)),
            ]);

            $encrypted++;
        }

        $this->info("Encrypted: {$encrypted}, already encrypted: {$skipped}");
        return self::SUCCESS;
    }
}