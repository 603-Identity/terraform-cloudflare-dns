terraform {
  required_version = ">= 1.10"

  required_providers {
    # source is pinned to the explicit registry.terraform.io host, not the
    # bare "cloudflare/cloudflare" shorthand, working around a Dependabot
    # bug (IAC-BL-28): a bare source with no host makes `tofu init`
    # generate a lockfile keyed to registry.opentofu.org (OpenTofu's own
    # default registry), but Dependabot's terraform-ecosystem updater
    # always assumes registry.terraform.io when no host is declared
    # (dependabot-core's file_updater.rb:436) and crashes with
    # `TypeError: T.cast: Expected type String, got type NilClass` when its
    # lockfile-declaration regex -- built for registry.terraform.io -- never
    # matches our registry.opentofu.org entries. Pinning the host here keeps
    # the lockfile and Dependabot's assumption in agreement; the provider
    # binary itself is unchanged, only fetched from Terraform's registry
    # rather than OpenTofu's mirror.
    cloudflare = {
      source  = "registry.terraform.io/cloudflare/cloudflare"
      version = "5.22.0"
    }
  }
}
