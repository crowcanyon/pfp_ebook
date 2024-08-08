# The Pueblo Farming Project eBook

This is the source code and data for the Pueblo Farming Project eBook, a publication of the [Crow Canyon Archaeological Center](https://crowcanyon.org).

<!-- badges: start -->

<!-- badges: end -->

## Updating the eBook

If you have "push" privileges for this repository, you can easily update the data and re-build this eBook. This eBook uses GitHub Actions for deployment, and GitHub Pages for hosting.

### Clone the repository

In a terminal, first clone the repository.

```{bash}
git clone git@github.com:crowcanyon/pfp_ebook.git
```

### Update the PFP Database
The PFP database is a Microsoft Access database hosted at the Crow Canyon Archaeological Center. In order to update the PFP eBook, an updated copy of that database needs to be placed in the `data` directory, and named `PFP_database.mdb`.

### Build the eBook locally (optional)
The eBook may be built locally on a computer with `R` installed. Simply change to the `pfp_ebook` directory and type `make gitbook` in the terminal. This will install any necessary software and re-build the eBook in the `docs` directory.

### Push the changes to GitHub
Once you add the new database and (optionally) re-build the eBook, commit and push your changes.

```{bash}
git pull
git add .
git commit -m "update PFP data" #Or any other message
git push
```

A push will trigger a new build in Github Actions.

