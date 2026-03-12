# zeroclaw-docker

Custom Docker image for ZeroClaw that adds Claude Code CLI and common development tooling.

Base image: `ghcr.io/zeroclaw-labs/zeroclaw:latest`

This image extends upstream ZeroClaw with:

- Claude Code CLI (`@anthropic-ai/claude-code`)
- Node.js and npm
- Git
- GitHub CLI
- Curl, Bash, and OpenSSH client

No `docker-compose` is included in this repository. It provides image build and publish only.

At container startup, this image requires `/zeroclaw-data` and `/repos` to be writable. If either directory is not writable, the container exits with an error so Swarm/Portainer can restart it after permissions are initialized.

For Swarm, run a one-shot init service to fix volume ownership, for example:

```yaml
init-permissions:
	image: alpine
	command: sh -c "chown -R 1000:1000 /zeroclaw-data /repos"
	volumes:
		- zeroclaw-data:/zeroclaw-data
		- repos:/repos
	deploy:
		restart_policy:
			condition: none
```

## Environment Variables

- `API_KEY` - LLM provider API key for ZeroClaw
- `PROVIDER` - LLM provider for ZeroClaw (default: `anthropic`)
- `ANTHROPIC_API_KEY` - API key used by Claude Code CLI
- `GIT_USER_NAME` - Sets global git `user.name` at container start
- `GIT_USER_EMAIL` - Sets global git `user.email` at container start
- `GITHUB_TOKEN` - Auth token for GitHub CLI and git push workflows
- `ZEROCLAW_ALLOW_PUBLIC_BIND` - Set `true` to allow public container networking
- `ZEROCLAW_GATEWAY_PORT` - ZeroClaw gateway port (default: `42617`)

## Pull Image

```bash
docker pull ghcr.io/ioleksiy/zeroclaw-docker:latest
```

## Run Example

```bash
docker run --rm -it \
	-e API_KEY="your-provider-key" \
	-e PROVIDER="anthropic" \
	-e ANTHROPIC_API_KEY="your-anthropic-key" \
	-e GIT_USER_NAME="Your Name" \
	-e GIT_USER_EMAIL="you@example.com" \
	-e GITHUB_TOKEN="ghp_xxx" \
	-e ZEROCLAW_ALLOW_PUBLIC_BIND="true" \
	-e ZEROCLAW_GATEWAY_PORT="42617" \
	-p 42617:42617 \
	ghcr.io/ioleksiy/zeroclaw-docker:latest
```

## Upstream

https://github.com/zeroclaw-labs/zeroclaw
