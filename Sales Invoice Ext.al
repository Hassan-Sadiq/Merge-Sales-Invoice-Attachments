pageextension 70006 "Sales Invoice Ext" extends "Posted Sales Invoice"
{
    layout
    {
        addlast(General)
        {
            usercontrol(pdf; PDF)
            {
                ApplicationArea = All;
                trigger DownloadPDF(pdfToNav: Text)
                var
                    TempBlob: Codeunit "Temp Blob";
                    Convert64: Codeunit "Base64 Convert";
                    Ins: InStream;
                    Outs: OutStream;
                    invoiceAttachments: Record "Invoice Attachments";
                    TempBlob2: Codeunit "Temp Blob";
                    Outs2: OutStream;
                begin
                    if pdfToNav <> '' then begin
                        TempBlob.CreateInStream(Ins);
                        TempBlob.CreateOutStream(Outs);
                        Convert64.FromBase64(pdfToNav, Outs);
                        TempBlob2.CreateOutStream(Outs2);
                        invoiceAttachments.SetFilter("Invoice No.", Rec."No.");

                        if invoiceAttachments.FindSet() then begin
                            repeat
                                invoiceAttachments.Delete();
                            until invoiceAttachments.Next() = 0;
                        end;

                        invoiceAttachments.Init();
                        invoiceAttachments."Invoice No." := Rec."No.";
                        invoiceAttachments.Content.ImportStream(Ins, 'Combined PDF');
                        invoiceAttachments.Insert();
                        MergePDF.ClearPDF();

                        SalesInvHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesInvHeader);
                        SalesInvHeader.EmailRecords(true);
                    end;
                end;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(Merge)
            {
                ApplicationArea = All;
                Caption = 'Email Combined Invoice with Attachments';
                Image = Email;
                Promoted = true;
                PromotedCategory = Category6;
                trigger OnAction()
                var
                    salesInvHeader: Record "Sales Invoice Header";
                    recRef: RecordRef;
                    DocumentAttachment: Record "Document Attachment";
                    TempBlob: Codeunit "Temp Blob";
                    FileInStream: InStream;
                    FileOutStream: OutStream;
                    base64Convert: Codeunit "Base64 Convert";
                    base64String: Text;
                begin
                    salesInvHeader.FindFirst();
                    salesInvHeader.SetRange("No.", Rec."No.");
                    recRef.GetTable(salesInvHeader);
                    MergePDF.AddReportToMerge(Report::"Standard Sales - Invoice", recRef);
                    DocumentAttachment.Reset();
                    DocumentAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
                    DocumentAttachment.SetRange("No.", Rec."No.");

                    If DocumentAttachment.FindSet() then begin
                        repeat
                            If DocumentAttachment."Document Reference ID".HasValue then begin
                                if DocumentAttachment."File Type" = "Document Attachment File Type"::PDF then begin
                                    Clear(TempBlob);
                                    TempBlob.CreateOutStream(FileOutStream);
                                    TempBlob.CreateInStream(FileInStream);
                                    DocumentAttachment."Document Reference ID".ExportStream(FileOutStream);
                                    base64String := base64Convert.ToBase64(FileInStream);
                                    MergePDF.AddBase64pdf(base64String);
                                end
                                else
                                    Error('Only PDF attachments supported');
                            end;
                        until DocumentAttachment.Next() = 0;
                    end;

                    // else begin
                    //     Error('No attachments found.');
                    // end;

                    CurrPage.pdf.MergePDF(format(MergePDF.GetJArray()));
                end;
            }
        }
    }
    var
        MergePDF: Codeunit "Merge PDF";
}