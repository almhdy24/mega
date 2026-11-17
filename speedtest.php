<?php
/**
 * MEGA | ميقا — Speed Test Backend (single file)
 * Upload to:  https://almhdy24.com/mega/speedtest.php
 *
 * Operations (all via ?op=):
 *   empty    GET/POST  -> empty 200 response. Used for ping and for upload (body is discarded).
 *   garbage  GET       -> streams ckSize MB of random bytes (download test). ?ckSize=1..MAX_DOWNLOAD_MB
 *   ip       GET       -> {"ip": "..."}
 *   info     GET       -> server name/version/limits (JSON). Default op.
 *
 * Notes:
 *  - Upload bodies must stay below PHP's post_max_size (default 8 MB). The app sends ~2.5 MB per request.
 *  - Each full test moves roughly 100-200 MB out of your hosting bandwidth. Tune the limits below.
 *  - Nothing is logged or stored except a tiny per-IP counter file in the system temp dir.
 */
declare(strict_types=1);

// ---------------- Settings (edit these) ----------------
const SERVER_NAME      = 'almhdy24.com';
const MAX_DOWNLOAD_MB  = 32;     // max size of one download request
const RATE_LIMIT_MB    = 1500;   // max download MB per IP per window
const RATE_WINDOW_SEC  = 600;    // window length (10 minutes)
const TRUST_CLOUDFLARE = false;  // set true only if the site is behind Cloudflare
// --------------------------------------------------------

ini_set('display_errors', '0');
ini_set('zlib.output_compression', '0');
if (function_exists('apache_setenv')) {
    @apache_setenv('no-gzip', '1');
}
header_remove('X-Powered-By');

function client_ip(): string
{
    if (TRUST_CLOUDFLARE && !empty($_SERVER['HTTP_CF_CONNECTING_IP'])) {
        return (string) $_SERVER['HTTP_CF_CONNECTING_IP'];
    }
    return (string) ($_SERVER['REMOTE_ADDR'] ?? '0.0.0.0');
}

function common_headers(): void
{
    header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
    header('Pragma: no-cache');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
}

/** Very small per-IP download budget. Fails open if the temp dir is not writable. */
function rate_limit(int $costMb): void
{
    $dir  = sys_get_temp_dir();
    $file = $dir . '/mega_st_' . sha1(client_ip());
    $now  = time();

    // Occasional cleanup of stale counter files (about 1 in 200 requests).
    if (random_int(1, 200) === 1) {
        foreach ((array) glob($dir . '/mega_st_*') as $f) {
            if (is_file($f) && $now - (int) filemtime($f) > RATE_WINDOW_SEC * 2) {
                @unlink($f);
            }
        }
    }

    $fh = @fopen($file, 'c+');
    if ($fh === false) {
        return;
    }
    flock($fh, LOCK_EX);
    $raw   = (string) stream_get_contents($fh);
    $parts = explode(',', $raw);
    $start = (int) ($parts[0] ?? 0);
    $used  = (int) ($parts[1] ?? 0);

    if ($start === 0 || $now - $start > RATE_WINDOW_SEC) {
        $start = $now;
        $used  = 0;
    }

    $allowed = ($used + $costMb) <= RATE_LIMIT_MB;
    if ($allowed) {
        $used += $costMb;
        ftruncate($fh, 0);
        rewind($fh);
        fwrite($fh, $start . ',' . $used);
    }
    flock($fh, LOCK_UN);
    fclose($fh);

    if (!$allowed) {
        http_response_code(429);
        header('Retry-After: ' . RATE_WINDOW_SEC);
        exit;
    }
}

$method = (string) ($_SERVER['REQUEST_METHOD'] ?? 'GET');
$op     = isset($_GET['op']) ? (string) $_GET['op'] : 'info';

common_headers();

if ($method === 'OPTIONS') {
    http_response_code(204);
    exit;
}

switch ($op) {
    case 'empty':
        header('Content-Length: 0');
        exit;

    case 'garbage':
        $mb = (int) ($_GET['ckSize'] ?? 20);
        $mb = max(1, min(MAX_DOWNLOAD_MB, $mb));
        rate_limit($mb);

        ignore_user_abort(false);
        set_time_limit(0);
        while (ob_get_level() > 0) {
            ob_end_clean();
        }

        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename=random.dat');
        header('Content-Transfer-Encoding: binary');
        header('Content-Length: ' . ($mb * 1048576));

        $chunk = random_bytes(1048576);
        for ($i = 0; $i < $mb; $i++) {
            echo $chunk;
            flush();
            if (connection_aborted()) {
                break;
            }
        }
        exit;

    case 'ip':
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['ip' => client_ip()]);
        exit;

    case 'info':
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'name'          => SERVER_NAME,
            'protocol'      => 'mega-1',
            'ops'           => ['empty', 'garbage', 'ip', 'info'],
            'maxDownloadMb' => MAX_DOWNLOAD_MB,
        ]);
        exit;

    default:
        http_response_code(400);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['error' => 'unknown op']);
        exit;
}
