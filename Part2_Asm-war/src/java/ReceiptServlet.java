/*
 * Receipt Servlet for APU Medical Center
 * Handles PDF receipt generation and download for completed and paid appointments
 */

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.Appointment;
import model.AppointmentFacade;
import model.Payment;
import model.PaymentFacade;
import model.Receipt;
import model.ReceiptFacade;
import model.Customer;

// For PDF generation - you'll need to add iText library to your project
import com.itextpdf.text.Document;
import com.itextpdf.text.DocumentException;
import com.itextpdf.text.Element;
import com.itextpdf.text.Font;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.Phrase;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;

@WebServlet(urlPatterns = {"/ReceiptServlet"})
public class ReceiptServlet extends HttpServlet {

    @EJB
    private AppointmentFacade appointmentFacade;
    
    @EJB
    private PaymentFacade paymentFacade;
    
    @EJB
    private ReceiptFacade receiptFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("download".equals(action)) {
            handleReceiptDownload(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp");
        }
    }

    /**
     * Handle receipt download request
     */
    private void handleReceiptDownload(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        try {
            // Get customer from session
            HttpSession session = request.getSession();
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");
            
            if (loggedInCustomer == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get appointment ID
            String appointmentIdStr = request.getParameter("appointment_id");
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=invalid_id");
                return;
            }
            
            int appointmentId = Integer.parseInt(appointmentIdStr);
            
            // Get appointment details
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=not_found");
                return;
            }
            
            // Verify appointment belongs to logged-in customer
            if (appointment.getCustomer() == null || 
                appointment.getCustomer().getId() != loggedInCustomer.getId()) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=unauthorized");
                return;
            }
            
            // Verify appointment is completed
            if (!"completed".equals(appointment.getStatus())) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=not_completed");
                return;
            }
            
            // Get payment details
            Payment payment = findPaymentByAppointment(appointmentId);
            if (payment == null || !"paid".equals(payment.getStatus())) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=payment_not_found");
                return;
            }
            
            // Check if receipt already exists
            Receipt existingReceipt = findReceiptByAppointment(appointmentId);
            if (existingReceipt != null && existingReceipt.getFilePath() != null) {
                // Check if file still exists
                File existingFile = new File(existingReceipt.getFilePath());
                if (existingFile.exists()) {
                    downloadFile(response, existingFile, "Receipt_" + appointmentId + ".pdf");
                    return;
                }
            }
            
            // Generate new receipt
            String receiptPath = generateReceiptPDF(appointment, payment);
            
            // Save receipt record to database
            saveReceiptRecord(appointment, payment, receiptPath);
            
            // Download the generated receipt
            File receiptFile = new File(receiptPath);
            downloadFile(response, receiptFile, "Receipt_" + appointmentId + ".pdf");
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=receipt_error");
        }
    }
    
    /**
     * Find payment by appointment ID
     */
    private Payment findPaymentByAppointment(int appointmentId) {
        try {
            return paymentFacade.findByAppointmentId(appointmentId);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
    
    /**
     * Find receipt by appointment ID
     */
    private Receipt findReceiptByAppointment(int appointmentId) {
        try {
            return receiptFacade.findByAppointmentId(appointmentId);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
    
    /**
     * Generate PDF receipt
     */
    private String generateReceiptPDF(Appointment appointment, Payment payment) 
            throws DocumentException, IOException {
        
        // Create downloads directory if it doesn't exist
        String downloadsPath = "C:\\Users\\leeja\\Downloads";
        File downloadsDir = new File(downloadsPath);
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs();
        }
        
        // Generate unique filename
        String fileName = "APU_Medical_Receipt_" + appointment.getId() + "_" + 
                         System.currentTimeMillis() + ".pdf";
        String filePath = downloadsPath + File.separator + fileName;
        
        // Create PDF document
        Document document = new Document(PageSize.A4);
        PdfWriter.getInstance(document, new FileOutputStream(filePath));
        
        document.open();
        
        // Define fonts
        Font titleFont = new Font(Font.FontFamily.HELVETICA, 18, Font.BOLD);
        Font headerFont = new Font(Font.FontFamily.HELVETICA, 14, Font.BOLD);
        Font normalFont = new Font(Font.FontFamily.HELVETICA, 10);
        Font boldFont = new Font(Font.FontFamily.HELVETICA, 10, Font.BOLD);
        
        // Medical center header
        Paragraph title = new Paragraph("APU MEDICAL CENTER", titleFont);
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(5);
        document.add(title);
        
        Paragraph address = new Paragraph("Technology Park Malaysia, 57000 Kuala Lumpur", normalFont);
        address.setAlignment(Element.ALIGN_CENTER);
        address.setSpacingAfter(20);
        document.add(address);
        
        // Receipt title
        Paragraph receiptTitle = new Paragraph("MEDICAL APPOINTMENT RECEIPT", headerFont);
        receiptTitle.setAlignment(Element.ALIGN_CENTER);
        receiptTitle.setSpacingAfter(20);
        document.add(receiptTitle);
        
        // Receipt details table
        PdfPTable detailsTable = new PdfPTable(2);
        detailsTable.setWidthPercentage(100);
        detailsTable.setSpacingAfter(20);
        
        // Date formatters
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
        SimpleDateFormat dateTimeFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        DecimalFormat currencyFormat = new DecimalFormat("0.00");
        
        // Add receipt details
        addTableRow(detailsTable, "Receipt No:", "R" + String.format("%06d", appointment.getId()), boldFont, normalFont);
        addTableRow(detailsTable, "Issue Date:", dateFormat.format(new Date()), boldFont, normalFont);
        addTableRow(detailsTable, "Appointment ID:", "A" + String.format("%06d", appointment.getId()), boldFont, normalFont);
        
        document.add(detailsTable);
        
        // Patient information
        Paragraph patientHeader = new Paragraph("PATIENT INFORMATION", headerFont);
        patientHeader.setSpacingAfter(10);
        document.add(patientHeader);
        
        PdfPTable patientTable = new PdfPTable(2);
        patientTable.setWidthPercentage(100);
        patientTable.setSpacingAfter(20);
        
        addTableRow(patientTable, "Patient Name:", appointment.getCustomer().getName(), boldFont, normalFont);
        addTableRow(patientTable, "Email:", appointment.getCustomer().getEmail(), boldFont, normalFont);
        if (appointment.getCustomer().getPhone() != null) {
            addTableRow(patientTable, "Phone:", appointment.getCustomer().getPhone(), boldFont, normalFont);
        }
        
        document.add(patientTable);
        
        // Appointment information
        Paragraph appointmentHeader = new Paragraph("APPOINTMENT DETAILS", headerFont);
        appointmentHeader.setSpacingAfter(10);
        document.add(appointmentHeader);
        
        PdfPTable appointmentTable = new PdfPTable(2);
        appointmentTable.setWidthPercentage(100);
        appointmentTable.setSpacingAfter(20);
        
        addTableRow(appointmentTable, "Doctor:", 
                   appointment.getDoctor() != null ? appointment.getDoctor().getName() : "N/A", 
                   boldFont, normalFont);
        
        if (appointment.getDoctor() != null && appointment.getDoctor().getSpecialization() != null) {
            addTableRow(appointmentTable, "Specialization:", 
                       appointment.getDoctor().getSpecialization(), boldFont, normalFont);
        }
        
        addTableRow(appointmentTable, "Treatment:", 
                   appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A", 
                   boldFont, normalFont);
        
        addTableRow(appointmentTable, "Date:", 
                   appointment.getAppointmentDate() != null ? 
                   dateFormat.format(appointment.getAppointmentDate()) : "N/A", 
                   boldFont, normalFont);
        
        addTableRow(appointmentTable, "Time:", 
                   appointment.getAppointmentTime() != null ? 
                   appointment.getAppointmentTime().toString() : "N/A", 
                   boldFont, normalFont);
        
        addTableRow(appointmentTable, "Status:", appointment.getStatus().toUpperCase(), boldFont, normalFont);
        
        document.add(appointmentTable);
        
        // Payment information
        Paragraph paymentHeader = new Paragraph("PAYMENT DETAILS", headerFont);
        paymentHeader.setSpacingAfter(10);
        document.add(paymentHeader);
        
        PdfPTable paymentTable = new PdfPTable(2);
        paymentTable.setWidthPercentage(100);
        paymentTable.setSpacingAfter(20);
        
        addTableRow(paymentTable, "Amount:", "RM " + currencyFormat.format(payment.getAmount()), boldFont, normalFont);
        addTableRow(paymentTable, "Payment Method:", 
                   payment.getPaymentMethod() != null ? 
                   payment.getPaymentMethod().toUpperCase() : "N/A", boldFont, normalFont);
        addTableRow(paymentTable, "Payment Status:", payment.getStatus().toUpperCase(), boldFont, normalFont);
        
        if (payment.getPaymentDate() != null) {
            addTableRow(paymentTable, "Payment Date:", 
                       dateTimeFormat.format(payment.getPaymentDate()), boldFont, normalFont);
        }
        
        document.add(paymentTable);
        
        // Footer
        Paragraph footer = new Paragraph("\nThank you for choosing APU Medical Center!\n" +
                                       "For any queries, please contact us at info@apumedical.com", normalFont);
        footer.setAlignment(Element.ALIGN_CENTER);
        footer.setSpacingBefore(30);
        document.add(footer);
        
        document.close();
        
        System.out.println("Receipt generated successfully: " + filePath);
        
        return filePath;
    }
    
    /**
     * Helper method to add table rows
     */
    private void addTableRow(PdfPTable table, String label, String value, Font labelFont, Font valueFont) {
        PdfPCell labelCell = new PdfPCell(new Phrase(label, labelFont));
        labelCell.setBorder(PdfPCell.NO_BORDER);
        labelCell.setPaddingBottom(5);
        table.addCell(labelCell);
        
        PdfPCell valueCell = new PdfPCell(new Phrase(value, valueFont));
        valueCell.setBorder(PdfPCell.NO_BORDER);
        valueCell.setPaddingBottom(5);
        table.addCell(valueCell);
    }
    
    /**
     * Save receipt record to database
     */
    private void saveReceiptRecord(Appointment appointment, Payment payment, String filePath) {
        try {
            Receipt receipt = new Receipt();
            receipt.setAppointment(appointment);
            receipt.setPayment(payment);
            receipt.setIssueDate(new Date());
            receipt.setFilePath(filePath);
            
            receiptFacade.create(receipt);
            
            System.out.println("Receipt record saved to database for appointment ID: " + appointment.getId());
            
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("Error saving receipt record: " + e.getMessage());
        }
    }
    
    /**
     * Download file to user's browser
     */
    private void downloadFile(HttpServletResponse response, File file, String downloadName) 
            throws IOException {
        
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + downloadName + "\"");
        response.setContentLength((int) file.length());
        
        java.io.FileInputStream fileInputStream = new java.io.FileInputStream(file);
        java.io.OutputStream responseOutputStream = response.getOutputStream();
        
        byte[] buffer = new byte[4096];
        int bytesRead;
        while ((bytesRead = fileInputStream.read(buffer)) != -1) {
            responseOutputStream.write(buffer, 0, bytesRead);
        }
        
        fileInputStream.close();
        responseOutputStream.flush();
        responseOutputStream.close();
    }

    @Override
    public String getServletInfo() {
        return "ReceiptServlet handles PDF receipt generation and download";
    }
}
