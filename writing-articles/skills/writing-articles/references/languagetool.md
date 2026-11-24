# Setting up LanguageTool

## Contents

- Which setup to choose
- Local server with Docker
- Better results with n-gram data
- Local server without Docker
- Public API
- Connect it to the checker
- Troubleshooting

`scripts/style_check.py` can send an article's prose to a LanguageTool server and add
its grammar and spelling matches as warnings. LanguageTool is open source
(LGPL-2.1) and checks German, English and more than 20 other languages. This file
explains how to get a server the checker can use. When helping a user set it up, run
the commands for them only with their consent: they install software and start a
service on their machine.

## Which setup to choose

| Setup | Privacy | Cost | Fits |
| --- | --- | --- | --- |
| Local server with Docker | Text stays on the machine | About 1 to 2 GB of RAM | The default for anyone writing regularly |
| Local server with n-gram data | Text stays on the machine | Plus 1.7 GB (German) or 9 GB (English) download, an SSD | Catches confused words such as "das"/"dass", "their"/"there" |
| Local server without Docker | Text stays on the machine | Java and about 250 MB | Machines without Docker |
| Public API | Text goes to LanguageTool's servers | Free, rate-limited | A quick try with short texts and the user's consent |

## Local server with Docker

The community image `erikvl87/languagetool` packages the official server and is kept
up to date with LanguageTool releases. It listens on port 8010.

```bash
docker run -d --name languagetool --restart unless-stopped \
  -p 127.0.0.1:8010:8010 \
  -e Java_Xms=512m -e Java_Xmx=2g \
  erikvl87/languagetool:6.8
```

- `127.0.0.1:` keeps the server reachable from this machine only. Leave it out only on
  purpose, for example on a server shared by a team behind a firewall.
- `--restart unless-stopped` starts it again after a reboot.
- `Java_Xmx` is the memory limit; the image defaults to 512 MB, which is tight for
  long articles. 2 GB is comfortable.
- Pin a version tag instead of `latest`, so an update does not change results silently.

The same as a Compose file, for example `~/languagetool/compose.yaml`:

```yaml
services:
  languagetool:
    image: erikvl87/languagetool:6.8
    container_name: languagetool
    restart: unless-stopped
    ports:
      - "127.0.0.1:8010:8010"
    environment:
      Java_Xms: 512m
      Java_Xmx: 2g
```

Start it with `docker compose up -d` in that directory. On macOS and Windows, Docker
Desktop or a compatible runtime is needed; the commands are the same.

## Better results with n-gram data

N-gram data lets LanguageTool spot words that are spelled correctly but wrong in
context. It exists for English, German, French and Spanish and is downloaded once from
the [n-gram data page](https://languagetool.org/download/ngram-data/): the German zip
is about 1.7 GB, the English one about 9 GB. Use an SSD; on a spinning disk the data
makes LanguageTool much slower.

Unzip each language into its own directory named by the language code, inside one
parent directory:

```
~/languagetool/ngrams/
├── de/   (from ngrams-de-*.zip)
└── en/   (from ngrams-en-*.zip)
```

Mount the parent directory and point `languageModel` at it, not at `de` or `en`:

```bash
docker run -d --name languagetool --restart unless-stopped \
  -p 127.0.0.1:8010:8010 \
  -e Java_Xms=512m -e Java_Xmx=2g \
  -e langtool_languageModel=/ngrams \
  -v "$HOME/languagetool/ngrams:/ngrams:ro" \
  erikvl87/languagetool:6.8
```

In Compose, add `langtool_languageModel: /ngrams` under `environment` and
`- ./ngrams:/ngrams:ro` under `volumes`. Recreate an existing container
(`docker rm -f languagetool`, then run again) to apply new options.

## Local server without Docker

1. Install Java 17 or newer.
2. Download and unzip the [current stable release](https://languagetool.org/download/LanguageTool-stable.zip)
   (about 250 MB).
3. Create an empty `server.properties` in the unzipped directory. For n-gram data, put
   one line in it: `languageModel=/path/to/ngrams`.
4. Start the server from that directory:

   ```bash
   java -cp languagetool-server.jar org.languagetool.server.HTTPServer \
     --config server.properties --port 8081
   ```

The server only answers requests from the same machine unless started with
`--public`. To keep it running, use the system's service manager (a systemd user
service, launchd, or a scheduled task). On macOS, `brew install languagetool` also
works; the LanguageTool team does not maintain that package.

## Public API

`https://api.languagetool.org` needs no setup, but it sends the text to LanguageTool's
servers. Use it only when the user agrees to that, never for unpublished client work.
Its [published limits](https://dev.languagetool.org/public-http-api) are 20 requests
and 75 KB of text per minute per IP, and 20 KB per request; the limits may change. The
checker sends one request per file, so a long article can exceed 20 KB and be
rejected. For regular use, run a local server.

## Connect it to the checker

Check that the server answers:

```bash
curl -s --data "language=de-DE" --data-urlencode "text=Ich glaube das das stimmt." \
  http://127.0.0.1:8010/v2/check
```

A JSON reply with a `matches` list means it works. Then either pass the URL each time:

```bash
python3 <skill-dir>/scripts/style_check.py --languagetool http://127.0.0.1:8010 content/blog/post.mdx
```

or set it once in the shell profile, so every run uses it:

```bash
export LANGUAGETOOL_URL=http://127.0.0.1:8010
```

Use port 8081 for a server started without Docker, and `https://api.languagetool.org`
for the public API.

## Troubleshooting

- `LanguageTool at … not used: Connection refused`: the server is not running or
  still starting. Starting takes up to a minute; check with `docker logs languagetool`.
- Out-of-memory errors or a container that restarts in a loop: raise `Java_Xmx`.
- N-gram rules have no effect: the mount or `languageModel` points at the language
  directory instead of its parent, or the zip was unpacked one level too deep. Check
  the startup lines of the log for errors about the language model.
- Many warnings about names and product terms: expected. The checker lists unknown
  words in one line per file; scan it for typos and ignore the names.
