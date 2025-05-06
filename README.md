# Costvine® Container

![Costvine](https://costvine.app/img/logo.svg)

Costvine is a web app for creating heirarchical budgets of all kinds. It's targeted at project managers and cost estimators in various industries, including finance, construction, manufacturing, and event planning.

This container is used for development and CI/CD tasks at [Costvine](https://costvine.com) (the same container is used for both). There are some sample supporting scripts in the `scripts` folder, however these are not burned into the container--they're intended to be run from the workspace after the container is loaded.

## Versions of Key Tools

The versions of Python, Node, PNPM and Poetry are all controlled through environment variables set in the Dockerfile. Everything else is essentially the latest stable version at the time the container was built. This container is refreshed periodically.

## Tools Included

- Astral's uv Python installer/package manager
- Python
- Poetry
- Node Version Manager (nvm)
- NodeJS (node)
- PNPM
- Google Cloud SDK (gcloud)
- Google Cloud Storage FUSE
- Google Cloud SQL Proxy
- Postgres client (psql)

## Support

This container is primarily used internally at Costvine and by a small number of commercial licensees of the Costvine components, and is constrained to serve that purpose, however you're welcome to use it in your own CDEs or CI/CI pipelines and we welcome any feedback.

Costvine itself is &copy; [John D. Underhill](mailto:john@costvine.com) and [Costvine, Inc](https://costvine.com). All rights reserved. The Costvine components published on [NPM](https://www.npmjs.com/) may be licensed for commercial use to selected entities or individuals. Contact the authors for details.
