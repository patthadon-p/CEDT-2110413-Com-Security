# Directory for auxiliary files
$aux_dir = '.build';

# Ensure the directory exists
if ( ! -d $aux_dir ) {
    mkdir $aux_dir or die "Failed to create directory $aux_dir: $!";
}

# Always enable SyncTeX
$pdflatex  = 'pdflatex  -synctex=1 -interaction=nonstopmode -file-line-error -aux-directory=' . $aux_dir;
$lualatex  = 'lualatex  -synctex=1 -interaction=nonstopmode -file-line-error';
$xelatex   = 'xelatex   -synctex=1 -interaction=nonstopmode -file-line-error';

# Build with XeLaTeX (pdf_mode 5): a Unicode engine is needed for the Thai
# support in CEDT-Assignment-style.sty (polyglossia + XeTeX's line breaker),
# and it's already the engine the notebook -> PDF path uses.
$pdf_mode = 5;

# XeTeX has no -aux-directory, only -output-directory; emulate_aux lets latexmk
# still keep the aux files in $aux_dir (.build) and copy the PDF back out.
$emulate_aux = 1;

# Move log-related files to aux dir
@generated_exts = qw(aux bbl blg fdb_latexmk fls log out toc lot lof listing);