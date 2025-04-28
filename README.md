# Take automatic screenshots of whole website 

## How it works

- curl to get the `sitemap.xml` from your website (must exist) in order to list pages to take screenshots of
- a headless docker container to take the screenshots (must have docker)
- ImageMagick to crop the image to the target width (defaults to 1280x630)

## Usage

### Requirements

- a `sitemap.xml`
- docker (recent enough to have `docker compose`)
- ImageMagick
- Linux or Linux-like system (typically a CI server or 24/7 other machine) and a way to trigger it (CI, cron job, manually, etc)

### Cron example

```cron
0 0 * * *  /opt/screenshots.sh -p /var/www/example.com/public/opengraph https://example.com >>/var/log/screenshots.log
```

#### Use generated images

The example above would generate all the screenshots every night into `/var/www/example.com/public/opengraph`.  
Each image would match the URL of the page with added `.png`, for example if URL is `/blog/123/article`, the image would be saved at `/var/www/example.com/public/opengraph/bloc/123/article.png`.

Your HTML would only need to contain something similar to:

```html
<html prefix="og: https://ogp.me/ns#">
<head>
...
<meta property="og:image" content="{{ canonical_host }}/opengraph/{{ canonical_path }}" />
...
</head>
...
</html>
```

Note: URLs ending with `/` will be named `index.png`.

### CLI arguments

- `-w 1280`: width (optional)
- `-h 630`: height (optional)
- `-p /path/to/images`: where to save the screenshots at
- URL: required, will be appended with `/sitemap.xml` to get the URL list

## Example

```bash
$ ./screenshot.sh -p opengraph https://youtilitics.com
[+] Pulling 1/1
 ✔ browserless Pulled                                                                                                                                                                                                                                     0.8s
[+] Running 1/1
 ✔ Container headless-screenshots-browserless-1  Running                                                                                                                                                                                                  0.0s
https://youtilitics.com/pr/2024-12-11 => pr/2024-12-11.png: PNG image data, 1280 x 630, 8-bit/color RGB, non-interlaced
https://youtilitics.com/ => index.png: PNG image data, 1280 x 630, 8-bit/color RGB, non-interlaced
https://youtilitics.com/privacy => privacy.png: PNG image data, 1280 x 630, 8-bit/color RGB, non-interlaced
https://youtilitics.com/watch/dashboard => watch/dashboard.png: PNG image data, 1280 x 630, 8-bit/color RGB, non-interlaced
[...]
```

Result with `index.png`:

```bash
$ xdg-open opengraph/index.png  #linux
$ open opengraph/index.png      #macos
```

![example with Youtilitics homepage](index.png "Example with Youtilitics homepage")

