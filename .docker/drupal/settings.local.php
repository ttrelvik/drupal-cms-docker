<?php

/**
 * @file
 * Local development customizations.
 *
 * This file contains settings that are specific to the local Docker environment,
 * such as reverse proxy configurations and trusted host patterns. It is managed
 * in Git and copied into place by the container's entrypoint script.
 */

// --- Trusted Host Patterns ---
// Read the domain from an environment variable to set the trusted host pattern.
// This prevents HTTP Host header attacks.
$domain = getenv('DOMAIN');
if ($domain) {
  $settings['trusted_host_patterns'] = [
    '^' . str_replace('.', '\.', $domain) . '$',
  ];
}

// --- Reverse Proxy Settings ---
// Read the trusted proxy CIDR from an environment variable.
$trusted_proxy_cidr = getenv('TRUSTED_PROXY_CIDR') ?: '127.0.0.1';

$settings['reverse_proxy_addresses'] = [$trusted_proxy_cidr];
$settings['reverse_proxy'] = TRUE;
$settings['reverse_proxy_trusted_headers'] = \Symfony\Component\HttpFoundation\Request::HEADER_X_FORWARDED_PROTO | \Symfony\Component\HttpFoundation\Request::HEADER_X_FORWARDED_FOR;
