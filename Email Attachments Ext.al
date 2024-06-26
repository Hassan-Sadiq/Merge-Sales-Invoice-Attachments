codeunit 70007 "Email Attachments Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeSendEmail', '', false, false)]
    local procedure DocumentMailing_OnBeforeSendEmail(var ReportUsage: Integer; var TempEmailItem: Record "Email Item"; var IsFromPostedDoc: Boolean; var PostedDocNo: Code[20])
    var
        names: list of [Text];
        tempBlobList: Codeunit "Temp Blob List";
        invAttachment: Text;
        tempBlob: Codeunit "Temp Blob";
    begin
        If IsFromPostedDoc And (ReportUsage = Enum::"Report Selection Usage"::"S.Invoice".AsInteger()) then
            TempEmailItem.GetAttachments(tempBlobList, names);

        invAttachment := names.Get(1);
        tempBlobList.RemoveAt(1);
        names.Remove(invAttachment);
        SendInvoiceAttachments(PostedDocNo, TempEmailItem);
    end;

    local procedure SendInvoiceAttachments(PostedSalesInvoiceNo: Code[20]; var TempEmailItem: Record "Email Item")
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        FileOutStream: OutStream;
        salesInvoiceReport: Report "Standard Sales - Invoice";
        invAttachments: Record "Invoice Attachments";
        fileName: Text;
    begin
        if PostedSalesInvoiceNo = '' then
            exit;

        fileName := 'Combined Sales Invoice ' + Format(PostedSalesInvoiceNo) + '.pdf';

        invAttachments.SetFilter("Invoice No.", PostedSalesInvoiceNo);

        if invAttachments.FindFirst() then begin
            TempBlob.CreateOutStream(FileOutStream);
            TempBlob.CreateInStream(FileInStream);
            invAttachments.Content.ExportStream(FileOutStream);
            TempEmailItem.AddAttachment(FileInStream, fileName);
            invAttachments.Delete();
        end;
    end;
}