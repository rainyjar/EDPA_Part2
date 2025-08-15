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

// iText PDF library imports for receipt generation (iText 5.x)
import com.itextpdf.text.*;
import com.itextpdf.text.pdf.*;
import com.itextpdf.text.BaseColor;
import com.itextpdf.text.Image;

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
import com.itextpdf.text.BaseColor;
import com.itextpdf.text.Image;

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
        
        // Handle both direct calls and action-based calls
        if ("download".equals(action) || request.getParameter("appointmentId") != null || request.getParameter("appointment_id") != null) {
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
            // Get user from session - can be either customer or counter staff
            HttpSession session = request.getSession();
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");
            Object counterStaff = session.getAttribute("counterStaff");
            
            // Check if either customer or counter staff is logged in
            if (loggedInCustomer == null && counterStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get appointment ID - handle multiple parameter names
            String appointmentIdStr = request.getParameter("appointment_id");
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                appointmentIdStr = request.getParameter("appointmentId");
            }
            
            // If no appointmentId, try to get it from paymentId
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                String paymentIdStr = request.getParameter("paymentId");
                if (paymentIdStr != null && !paymentIdStr.trim().isEmpty()) {
                    try {
                        int paymentId = Integer.parseInt(paymentIdStr);
                        Payment payment = paymentFacade.find(paymentId);
                        if (payment != null && payment.getAppointment() != null) {
                            appointmentIdStr = String.valueOf(payment.getAppointment().getId());
                        }
                    } catch (NumberFormatException e) {
                        // Invalid paymentId format
                    }
                }
            }
            
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                if (loggedInCustomer != null) {
                    response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=invalid_id");
                } else {
                    response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewPayments&error=invalid_id");
                }
                return;
            }
            
            int appointmentId = Integer.parseInt(appointmentIdStr);
            
            // Get appointment details
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                if (loggedInCustomer != null) {
                    response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=not_found");
                } else {
                    response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewPayments&error=appointment_not_found");
                }
                return;
            }
            
            // Authorization check - different rules for customer vs staff
            if (loggedInCustomer != null) {
                // Customer can only access their own appointments
                if (appointment.getCustomer() == null || 
                    appointment.getCustomer().getId() != loggedInCustomer.getId()) {
                    response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=unauthorized");
                    return;
                }
            }
            // Counter staff can access any appointment (no additional check needed)
            
            // Verify appointment is completed
            if (!"completed".equals(appointment.getStatus())) {
                if (loggedInCustomer != null) {
                    response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=not_completed");
                } else {
                    response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewPayments&error=appointment_not_completed");
                }
                return;
            }
            
            // Get payment details
            Payment payment = findPaymentByAppointment(appointmentId);
            if (payment == null || !"paid".equals(payment.getStatus())) {
                if (loggedInCustomer != null) {
                    response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=payment_not_found");
                } else {
                    response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewPayments&error=payment_not_paid");
                }
                return;
            }
            
            // Check if receipt already exists in database (for record keeping)
            Receipt existingReceipt = findReceiptByAppointment(appointmentId);
            
            // Generate PDF filename for download
            String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
            String patientName = appointment.getCustomer().getName().replaceAll("[^a-zA-Z0-9]", "_");
            String filename = "AMC_Receipt_" + patientName + "_Appointment" + appointment.getId() + "_" + timestamp + ".pdf";
            
            // Generate and stream PDF directly to browser
            generateAndStreamReceiptPDF(response, appointment, payment, filename);
            
            // Save receipt record to database if it doesn't exist
            if (existingReceipt == null) {
                saveReceiptRecord(appointment, payment); 
            }
            
        } catch (NumberFormatException e) {
            HttpSession session = request.getSession();
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");
            if (loggedInCustomer != null) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=invalid_id");
            } else {
                response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewPayments&error=invalid_id");
            }
        } catch (Exception e) {
            e.printStackTrace();
            HttpSession session = request.getSession();
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");
            if (loggedInCustomer != null) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=receipt_error");
            } else {
                response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewPayments&error=receipt_error");
            }
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
     * Generate PDF receipt and stream directly to browser
     */
    private void generateAndStreamReceiptPDF(HttpServletResponse response, Appointment appointment, Payment payment, String filename) 
            throws DocumentException, IOException {
        
        // Set response headers for PDF download
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        
        // Create PDF document with smaller margins for more content
        Document document = new Document(PageSize.A4, 40, 40, 30, 30);
        
        // Write directly to response output stream
        PdfWriter.getInstance(document, response.getOutputStream());
        document.open();
        
        // Define professional color scheme
        BaseColor primaryBlue = new BaseColor(41, 128, 185);    // Professional blue
        BaseColor lightGray = new BaseColor(236, 240, 241);     // Light background
        BaseColor darkGray = new BaseColor(52, 73, 94);         // Dark text
        BaseColor accentGreen = new BaseColor(39, 174, 96);     // Success green
        
        // Define enhanced fonts with consistent sizing
        Font titleFont = new Font(Font.FontFamily.HELVETICA, 22, Font.BOLD, primaryBlue);
        Font headerFont = new Font(Font.FontFamily.HELVETICA, 14, Font.BOLD, darkGray);
        Font subHeaderFont = new Font(Font.FontFamily.HELVETICA, 12, Font.BOLD, primaryBlue);
        Font boldFont = new Font(Font.FontFamily.HELVETICA, 10, Font.BOLD, BaseColor.BLACK);
        Font normalFont = new Font(Font.FontFamily.HELVETICA, 10, Font.NORMAL, BaseColor.BLACK);
        Font smallFont = new Font(Font.FontFamily.HELVETICA, 8, Font.NORMAL, BaseColor.GRAY);
        Font amountFont = new Font(Font.FontFamily.HELVETICA, 12, Font.BOLD, accentGreen);
        
        // === HEADER SECTION ===
        PdfPTable headerTable = new PdfPTable(2);
        headerTable.setWidthPercentage(100);
        headerTable.setWidths(new float[]{1.2f, 2.8f});
        headerTable.setSpacingAfter(20);
        
        // Logo cell with border
        PdfPCell logoCell = new PdfPCell();
        logoCell.setBorder(Rectangle.BOX);
        logoCell.setBorderColor(lightGray);
        logoCell.setPadding(10);
        logoCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        
        try {
            String logoPath = this.getServletContext().getRealPath("/images/amc_logo.png");
            File logoFile = new File(logoPath);
            if (logoFile.exists()) {
                Image logo = Image.getInstance(logoPath);
                logo.scaleToFit(70, 70);
                logo.setAlignment(Element.ALIGN_CENTER);
                logoCell.addElement(logo);
            } else {
                // Fallback logo placeholder
                Paragraph logoText = new Paragraph("AMC", new Font(Font.FontFamily.HELVETICA, 20, Font.BOLD, primaryBlue));
                logoText.setAlignment(Element.ALIGN_CENTER);
                logoCell.addElement(logoText);
            }
        } catch (Exception e) {
            // Fallback logo placeholder
            Paragraph logoText = new Paragraph("AMC", new Font(Font.FontFamily.HELVETICA, 20, Font.BOLD, primaryBlue));
            logoText.setAlignment(Element.ALIGN_CENTER);
            logoCell.addElement(logoText);
        }
        headerTable.addCell(logoCell);
        
        // Medical center info cell with styling
        PdfPCell infoCell = new PdfPCell();
        infoCell.setBorder(Rectangle.BOX);
        infoCell.setBorderColor(lightGray);
        infoCell.setPadding(10);
        infoCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        
        Paragraph centerInfo = new Paragraph();
        centerInfo.add(new Phrase("APU MEDICAL CENTER\n", new Font(Font.FontFamily.HELVETICA, 18, Font.BOLD, primaryBlue)));
        centerInfo.add(new Phrase("Professional Healthcare Services\n\n", new Font(Font.FontFamily.HELVETICA, 10, Font.ITALIC, darkGray)));
        centerInfo.add(new Phrase("+60 10-070-0170\n", smallFont));
        centerInfo.add(new Phrase("info@amc.com\n", smallFont));
        centerInfo.add(new Phrase("Technology Park Malaysia\n", smallFont));
        centerInfo.add(new Phrase("Bukit Jalil, 57000 Kuala Lumpur", smallFont));
        centerInfo.setAlignment(Element.ALIGN_LEFT);
        infoCell.addElement(centerInfo);
        headerTable.addCell(infoCell);
        
        document.add(headerTable);
        
        // === RECEIPT TITLE SECTION ===
        PdfPTable titleTable = new PdfPTable(1);
        titleTable.setWidthPercentage(100);
        titleTable.setSpacingAfter(15);
        
        PdfPCell titleCell = new PdfPCell();
        titleCell.setBorder(Rectangle.BOX);
        titleCell.setBorderColor(primaryBlue);
        titleCell.setBorderWidth(2);
        titleCell.setBackgroundColor(lightGray);
        titleCell.setPadding(12);
        
        Paragraph titlePara = new Paragraph("PAYMENT RECEIPT", titleFont);
        titlePara.setAlignment(Element.ALIGN_CENTER);
        titleCell.addElement(titlePara);
        titleTable.addCell(titleCell);
        document.add(titleTable);
        
        // Date formatters
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
        SimpleDateFormat dateTimeFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        DecimalFormat currencyFormat = new DecimalFormat("0.00");
        
        // === RECEIPT DETAILS SECTION ===
        PdfPTable detailsTable = new PdfPTable(4);
        detailsTable.setWidthPercentage(100);
        detailsTable.setWidths(new float[]{1f, 1.5f, 1f, 1.5f});
        detailsTable.setSpacingAfter(15);
        
        addSectionHeader(detailsTable, "RECEIPT DETAILS", subHeaderFont, lightGray, 4);
        addDetailRow(detailsTable, "Receipt No:", "AMC-R" + String.format("%06d", appointment.getId()), 
                    "Issue Date:", dateFormat.format(new Date()), boldFont, normalFont);
        addDetailRow(detailsTable, "Appointment ID:", "AMC-A" + String.format("%06d", appointment.getId()), 
                    "Status:", "COMPLETED & PAID", boldFont, normalFont);
        
        document.add(detailsTable);
        
        // === PATIENT INFORMATION SECTION ===
        PdfPTable patientTable = new PdfPTable(2);
        patientTable.setWidthPercentage(100);
        patientTable.setWidths(new float[]{1f, 2f});
        patientTable.setSpacingAfter(12);
        
        addSectionHeader(patientTable, "PATIENT INFORMATION", subHeaderFont, lightGray, 2);
        addStyledDetailRow(patientTable, "Patient Name:", appointment.getCustomer().getName(), boldFont, normalFont);
        addStyledDetailRow(patientTable, "Email Address:", appointment.getCustomer().getEmail(), boldFont, normalFont);
        
        if (appointment.getCustomer().getPhone() != null && !appointment.getCustomer().getPhone().trim().isEmpty()) {
            addStyledDetailRow(patientTable, "Phone Number:", appointment.getCustomer().getPhone(), boldFont, normalFont);
        }
        
        document.add(patientTable);
        
        // === APPOINTMENT DETAILS SECTION ===
        PdfPTable appointmentTable = new PdfPTable(2);
        appointmentTable.setWidthPercentage(100);
        appointmentTable.setWidths(new float[]{1f, 2f});
        appointmentTable.setSpacingAfter(12);
        
        addSectionHeader(appointmentTable, "APPOINTMENT DETAILS", subHeaderFont, lightGray, 2);
        
        if (appointment.getAppointmentDate() != null) {
            addStyledDetailRow(appointmentTable, "Appointment Date:", dateFormat.format(appointment.getAppointmentDate()), boldFont, normalFont);
        }
        if (appointment.getAppointmentTime() != null) {
            addStyledDetailRow(appointmentTable, "Appointment Time:", appointment.getAppointmentTime().toString(), boldFont, normalFont);
        }
        if (appointment.getDoctor() != null) {
            addStyledDetailRow(appointmentTable, "Attending Doctor:", appointment.getDoctor().getName(), boldFont, normalFont);
            if (appointment.getDoctor().getSpecialization() != null) {
                addStyledDetailRow(appointmentTable, "Specialization:", appointment.getDoctor().getSpecialization(), boldFont, normalFont);
            }
        }
        if (appointment.getTreatment() != null) {
            addStyledDetailRow(appointmentTable, "Treatment/Service:", appointment.getTreatment().getName(), boldFont, normalFont);
        }
        if (appointment.getCounterStaff() != null) {
            addStyledDetailRow(appointmentTable, "Assisted By:", appointment.getCounterStaff().getName(), boldFont, normalFont);
        }
        
        document.add(appointmentTable);
        
        // === PAYMENT INFORMATION SECTION ===
        PdfPTable paymentTable = new PdfPTable(2);
        paymentTable.setWidthPercentage(100);
        paymentTable.setWidths(new float[]{1f, 2f});
        paymentTable.setSpacingAfter(15);
        
        addSectionHeader(paymentTable, "PAYMENT INFORMATION", subHeaderFont, lightGray, 2);
        
        // Payment amount with special styling
        PdfPCell amountLabelCell = new PdfPCell(new Phrase("Total Amount:", boldFont));
        amountLabelCell.setBorder(Rectangle.LEFT | Rectangle.RIGHT);
        amountLabelCell.setBorderColor(BaseColor.LIGHT_GRAY);
        amountLabelCell.setPadding(8);
        amountLabelCell.setBackgroundColor(new BaseColor(248, 249, 250));
        paymentTable.addCell(amountLabelCell);
        
        PdfPCell amountValueCell = new PdfPCell(new Phrase("RM " + currencyFormat.format(payment.getAmount()), amountFont));
        amountValueCell.setBorder(Rectangle.LEFT | Rectangle.RIGHT);
        amountValueCell.setBorderColor(BaseColor.LIGHT_GRAY);
        amountValueCell.setPadding(8);
        amountValueCell.setBackgroundColor(new BaseColor(248, 249, 250));
        paymentTable.addCell(amountValueCell);
        
        addStyledDetailRow(paymentTable, "Payment Method:", 
                   payment.getPaymentMethod() != null ? payment.getPaymentMethod().toUpperCase() : "N/A", boldFont, normalFont);
        addStyledDetailRow(paymentTable, "Payment Status:", "✓ " + payment.getStatus().toUpperCase(), boldFont, new Font(Font.FontFamily.HELVETICA, 10, Font.BOLD, accentGreen));
        
        if (payment.getPaymentDate() != null) {
            addStyledDetailRow(paymentTable, "Payment Date:", dateTimeFormat.format(payment.getPaymentDate()), boldFont, normalFont);
        }
        
        // Add bottom border to payment table
        PdfPCell bottomBorderCell1 = new PdfPCell();
        bottomBorderCell1.setBorder(Rectangle.BOTTOM);
        bottomBorderCell1.setBorderColor(BaseColor.LIGHT_GRAY);
        bottomBorderCell1.setFixedHeight(1);
        paymentTable.addCell(bottomBorderCell1);
        
        PdfPCell bottomBorderCell2 = new PdfPCell();
        bottomBorderCell2.setBorder(Rectangle.BOTTOM);
        bottomBorderCell2.setBorderColor(BaseColor.LIGHT_GRAY);
        bottomBorderCell2.setFixedHeight(1);
        paymentTable.addCell(bottomBorderCell2);
        
        document.add(paymentTable);
        
        // === FOOTER SECTION ===
        // Thank you message with box
        PdfPTable thankYouTable = new PdfPTable(1);
        thankYouTable.setWidthPercentage(100);
        thankYouTable.setSpacingBefore(10);
        thankYouTable.setSpacingAfter(10);
        
        PdfPCell thankYouCell = new PdfPCell();
        thankYouCell.setBorder(Rectangle.BOX);
        thankYouCell.setBorderColor(accentGreen);
        thankYouCell.setBackgroundColor(new BaseColor(232, 245, 233));
        thankYouCell.setPadding(12);
        
        Paragraph thankYouPara = new Paragraph("Thank you for choosing APU Medical Center!", 
                                             new Font(Font.FontFamily.HELVETICA, 14, Font.BOLD, accentGreen));
        thankYouPara.setAlignment(Element.ALIGN_CENTER);
        thankYouCell.addElement(thankYouPara);
        thankYouTable.addCell(thankYouCell);
        document.add(thankYouTable);
        
        // Footer information
        Paragraph footerInfo = new Paragraph();
        footerInfo.add(new Phrase("• This is a computer-generated receipt and does not require a signature\n", smallFont));
        footerInfo.add(new Phrase("• For inquiries, please contact us at +60 10-070-0170 or info@amc.com\n", smallFont));
        footerInfo.add(new Phrase("• Keep this receipt for your records and insurance claims", smallFont));
        footerInfo.setAlignment(Element.ALIGN_CENTER);
        footerInfo.setSpacingBefore(8);
        footerInfo.setSpacingAfter(8);
        document.add(footerInfo);
        
        // Generation timestamp in bottom right
        Paragraph timestamp = new Paragraph("Generated on: " + dateTimeFormat.format(new Date()), 
                                          new Font(Font.FontFamily.HELVETICA, 8, Font.ITALIC, BaseColor.GRAY));
        timestamp.setAlignment(Element.ALIGN_RIGHT);
        document.add(timestamp);
        
        document.close();
    }
    
    /**
     * Helper method to add styled table rows
     */
    private void addStyledTableRow(PdfPTable table, String label, String value, Font labelFont, Font valueFont) {
        PdfPCell labelCell = new PdfPCell(new Phrase(label, labelFont));
        labelCell.setBorder(PdfPCell.NO_BORDER);
        labelCell.setPaddingBottom(8);
        labelCell.setPaddingTop(5);
        table.addCell(labelCell);
        
        PdfPCell valueCell = new PdfPCell(new Phrase(value, valueFont));
        valueCell.setBorder(PdfPCell.NO_BORDER);
        valueCell.setPaddingBottom(8);
        valueCell.setPaddingTop(5);
        table.addCell(valueCell);
    }
    
    /**
     * Helper method to add section headers with background color
     */
    private void addSectionHeader(PdfPTable table, String headerText, Font headerFont, BaseColor backgroundColor, int colspan) {
        PdfPCell headerCell = new PdfPCell(new Phrase(headerText, headerFont));
        headerCell.setColspan(colspan);
        headerCell.setBorder(Rectangle.BOX);
        headerCell.setBorderColor(BaseColor.LIGHT_GRAY);
        headerCell.setBackgroundColor(backgroundColor);
        headerCell.setPadding(8);
        headerCell.setHorizontalAlignment(Element.ALIGN_LEFT);
        table.addCell(headerCell);
    }
    
    /**
     * Helper method to add detail rows for 4-column layout
     */
    private void addDetailRow(PdfPTable table, String label1, String value1, String label2, String value2, Font labelFont, Font valueFont) {
        // First label-value pair
        PdfPCell labelCell1 = new PdfPCell(new Phrase(label1, labelFont));
        labelCell1.setBorder(Rectangle.LEFT | Rectangle.RIGHT);
        labelCell1.setBorderColor(BaseColor.LIGHT_GRAY);
        labelCell1.setPadding(6);
        table.addCell(labelCell1);
        
        PdfPCell valueCell1 = new PdfPCell(new Phrase(value1, valueFont));
        valueCell1.setBorder(Rectangle.LEFT | Rectangle.RIGHT);
        valueCell1.setBorderColor(BaseColor.LIGHT_GRAY);
        valueCell1.setPadding(6);
        table.addCell(valueCell1);
        
        // Second label-value pair
        PdfPCell labelCell2 = new PdfPCell(new Phrase(label2, labelFont));
        labelCell2.setBorder(Rectangle.LEFT | Rectangle.RIGHT);
        labelCell2.setBorderColor(BaseColor.LIGHT_GRAY);
        labelCell2.setPadding(6);
        table.addCell(labelCell2);
        
        PdfPCell valueCell2 = new PdfPCell(new Phrase(value2, valueFont));
        valueCell2.setBorder(Rectangle.LEFT | Rectangle.RIGHT);
        valueCell2.setBorderColor(BaseColor.LIGHT_GRAY);
        valueCell2.setPadding(6);
        table.addCell(valueCell2);
    }
    
    /**
     * Helper method to add styled detail rows with borders
     */
    private void addStyledDetailRow(PdfPTable table, String label, String value, Font labelFont, Font valueFont) {
        PdfPCell labelCell = new PdfPCell(new Phrase(label, labelFont));
        labelCell.setBorder(Rectangle.LEFT | Rectangle.RIGHT);
        labelCell.setBorderColor(BaseColor.LIGHT_GRAY);
        labelCell.setPadding(6);
        labelCell.setBackgroundColor(new BaseColor(248, 249, 250));
        table.addCell(labelCell);
        
        PdfPCell valueCell = new PdfPCell(new Phrase(value, valueFont));
        valueCell.setBorder(Rectangle.LEFT | Rectangle.RIGHT);
        valueCell.setBorderColor(BaseColor.LIGHT_GRAY);
        valueCell.setPadding(6);
        table.addCell(valueCell);
    }
    
    /**
     * Helper method to add table rows (legacy support)
     */
    private void addTableRow(PdfPTable table, String label, String value, Font labelFont, Font valueFont) {
        addStyledTableRow(table, label, value, labelFont, valueFont);
    }
    
    /**
     * Save receipt record to database
     */
    private void saveReceiptRecord(Appointment appointment, Payment payment) {
        try {
            Receipt receipt = new Receipt();
            receipt.setAppointment(appointment);
            receipt.setPayment(payment);
            receipt.setIssueDate(new Date());
            
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
