<?php

/**
 * @file
 * Local development customizations.
 * 
 * In order for this file to be used, settings.local.php must be included
 * from settings.php. Find the following 3 lines in settings.php and uncomment
 * them (future settings.php versions may differ):
 * if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
 *   include $app_root . '/' . $site_path . '/settings.local.php';
 * }
 *
 * This file contains settings that are specific to the local Docker environment,
 * such as reverse proxy configurations and trusted host patterns. It is managed
 * in Git and copied into place by the container's entrypoint script.
 */

// --- Trusted Host Patterns ---
$trusted_hosts = [];

// Add the primary domain from the DOMAIN environment variable
$domain = getenv('DOMAIN');
if ($domain) {
  $trusted_hosts[] = '^' . str_replace('.', '\.', $domain) . '$';
}

// Add any additional domains from the ADDITIONAL_TRUSTED_HOSTS environment variable
$additional_hosts = getenv('ADDITIONAL_TRUSTED_HOSTS');
if ($additional_hosts) {
  $host_list = explode(',', $additional_hosts);
  foreach ($host_list as $host) {
    $trusted_hosts[] = '^' . str_replace('.', '\.', trim($host)) . '$';
  }
}

if (!empty($trusted_hosts)) {
  $settings['trusted_host_patterns'] = $trusted_hosts;
}

// --- Reverse Proxy Settings ---
// Read the trusted proxy CIDR from an environment variable.
$trusted_proxy_cidr = getenv('TRUSTED_PROXY_CIDR') ?: '127.0.0.1';

$settings['reverse_proxy_addresses'] = [$trusted_proxy_cidr];
$settings['reverse_proxy'] = TRUE;
$settings['reverse_proxy_trusted_headers'] = \Symfony\Component\HttpFoundation\Request::HEADER_X_FORWARDED_PROTO | \Symfony\Component\HttpFoundation\Request::HEADER_X_FORWARDED_FOR;
