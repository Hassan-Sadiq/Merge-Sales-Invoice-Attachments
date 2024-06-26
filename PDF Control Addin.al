controladdin PDF
{
    Scripts = 'script/pdf-lib.min.js',
    'script/scripts.js';

    MaximumHeight = 1;
    MaximumWidth = 1;
    event DownloadPDF(stringpdffinal: text);
    procedure createPdf();
    procedure MergePDF(JObjectToMerge: text);

}