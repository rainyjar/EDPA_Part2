import java.io.IOException;
import java.io.OutputStream;
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
import model.Doctor;
import model.MedicalCertificate;
import model.MedicalCertificateFacade;
import com.itextpdf.text.Document;
import com.itextpdf.text.DocumentException;
import com.itextpdf.text.Element;
import com.itextpdf.text.Font;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.pdf.PdfWriter;


@WebServlet(name = "MedicalCertificateServlet", urlPatterns = {"/MedicalCertificateServlet"})
public class MedicalCertificateServlet extends HttpServlet {

    @EJB
    private AppointmentFacade appointmentFacade;
    
    @EJB
    private MedicalCertificateFacade mcFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        switch (action != null ? action : "") {
            case "showForm":
                handleShowForm(request, response);
                break;
            case "download":
                handleDownload(request, response);
                break;
            default:
                // Default: try to download MC by appointment ID
                handleDownload(request, response);
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("createMC".equals(action)) {
            handleCreateMC(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
        }
    }
    
    /**
     * Handle showing the MC form for doctors
     */
    private void handleShowForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            HttpSession session = request.getSession();
            Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
            
            if (loggedInDoctor == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                request.setAttribute("error", "Appointment not found");
                response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewAssignedAppointments");
                return;
            }
            
            // Validate doctor owns this appointment
            if (appointment.getDoctor() == null || appointment.getDoctor().getId() != loggedInDoctor.getId()) {
                request.setAttribute("error", "Unauthorized access to appointment");
                response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewAssignedAppointments");
                return;
            }
            
            // Check if appointment is completed
            if (!"completed".equals(appointment.getStatus())) {
                request.setAttribute("error", "Only completed appointments can have medical certificates");
                response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewAssignedAppointments");
                return;
            }
            
            // Check if MC already exists
            MedicalCertificate existingMC = mcFacade.findByAppointmentId(appointmentId);
            
            request.setAttribute("appointment", appointment);
            request.setAttribute("existingMC", existingMC);
            request.setAttribute("doctor", loggedInDoctor);
            
            request.getRequestDispatcher("/doctor/generate_mc.jsp").forward(request, response);
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid appointment ID");
            response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewAssignedAppointments");
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to load MC form: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/PaymentServlet?action=viewAssignedAppointments");
        }
    }
    
    /**
     * Handle creating/updating MC
     */
    private void handleCreateMC(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            HttpSession session = request.getSession();
            Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
            
            if (loggedInDoctor == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get parameters
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            String startDate = request.getParameter("startDate");
            String endDate = request.getParameter("endDate");
            String reason = request.getParameter("reason");
            String additionalNotes = request.getParameter("additionalNotes");
            
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                request.setAttribute("error", "Appointment not found");
                handleShowForm(request, response);
                return;
            }
            
            // Create or update MC
            MedicalCertificate mc = mcFacade.findByAppointmentId(appointmentId);
            if (mc == null) {
                mc = new MedicalCertificate();
                mc.setAppointment(appointment);
                mc.setDoctor(loggedInDoctor);
                mc.setIssueDate(new Date());
            }
            
            mc.setStartDate(java.sql.Date.valueOf(startDate));
            mc.setEndDate(java.sql.Date.valueOf(endDate));
            mc.setReason(reason);
            mc.setAdditionalNotes(additionalNotes);
            
            if (mc.getId() == 0) {
                mcFacade.create(mc);
                // Redirect back to generateMC view with success message
                response.sendRedirect(request.getContextPath() + "/DoctorServlet?action=generateMC&success=Medical certificate created successfully");
            } else {
                mcFacade.edit(mc);
                // Redirect back to generateMC view with success message
                response.sendRedirect(request.getContextPath() + "/DoctorServlet?action=generateMC&success=Medical certificate updated successfully");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to save MC: " + e.getMessage());
            handleShowForm(request, response);
        }
    }
    
    /**
     * Handle downloading MC as PDF
     */
    private void handleDownload(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Check authentication - allow doctors and counter staff
            HttpSession session = request.getSession();
            Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
            Object counterStaff = session.getAttribute("staff"); // Fixed: consistent with other servlets
            
            if (loggedInDoctor == null && counterStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            
            MedicalCertificate mc = mcFacade.findByAppointmentId(appointmentId);
            if (mc == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                response.getWriter().write("Medical Certificate not found");
                return;
            }
            
            Appointment appointment = mc.getAppointment();
            Doctor doctor = mc.getDoctor();
            
            // Set response headers for PDF download
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=\"MC_Appointment_" + appointmentId + ".pdf\"");
            
            // Create PDF document
            Document document = new Document(PageSize.A4);
            OutputStream out = response.getOutputStream();
            PdfWriter.getInstance(document, out);
            
            document.open();
            
            // Define fonts
            Font titleFont = new Font(Font.FontFamily.HELVETICA, 18, Font.BOLD);
            Font headerFont = new Font(Font.FontFamily.HELVETICA, 14, Font.BOLD);
            Font normalFont = new Font(Font.FontFamily.HELVETICA, 12, Font.NORMAL);
            Font smallFont = new Font(Font.FontFamily.HELVETICA, 10, Font.NORMAL);
            
            SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMMM yyyy");
            SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
            
            // Medical Center Header
            Paragraph centerName = new Paragraph("APU MEDICAL CENTER", titleFont);
            centerName.setAlignment(Element.ALIGN_CENTER);
            document.add(centerName);
            
            Paragraph centerAddress = new Paragraph("Technology Park Malaysia, 57000 Kuala Lumpur\nTel: +603-8996-1000 | Email: info@apu.edu.my", normalFont);
            centerAddress.setAlignment(Element.ALIGN_CENTER);
            document.add(centerAddress);
            
            document.add(new Paragraph(" ")); // Empty line
            
            // Document Title
            Paragraph title = new Paragraph("MEDICAL CERTIFICATE", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            document.add(title);
            
            document.add(new Paragraph(" ")); // Empty line
            
            // Patient Information
            document.add(new Paragraph("Patient Details:", headerFont));
            document.add(new Paragraph("Name: " + (appointment.getCustomer() != null ? appointment.getCustomer().getName() : "N/A"), normalFont));
            document.add(new Paragraph("IC No: " + (appointment.getCustomer() != null ? appointment.getCustomer().getIc() : "N/A"), normalFont));
            document.add(new Paragraph("Age: " + calculateAge(appointment.getCustomer().getDob()), normalFont));
            document.add(new Paragraph("Gender: " + (appointment.getCustomer().getGender() != null ? appointment.getCustomer().getGender() : "N/A"), normalFont));
            
            document.add(new Paragraph(" ")); // Empty line
            
            // Medical Statement
            document.add(new Paragraph("Medical Statement:", headerFont));
            Paragraph statement = new Paragraph(
                "This is to certify that the above-named individual has been examined " +
                "and found to be medically unfit for work/school from " +
                dateFormat.format(mc.getStartDate()) + " to " + dateFormat.format(mc.getEndDate()) + ".",
                normalFont
            );
            document.add(statement);
            
            document.add(new Paragraph(" ")); // Empty line
            
            // Reason
            if (mc.getReason() != null && !mc.getReason().trim().isEmpty()) {
                document.add(new Paragraph("Reason: " + mc.getReason(), normalFont));
                document.add(new Paragraph(" ")); // Empty line
            }
            
            // Additional Notes
            if (mc.getAdditionalNotes() != null && !mc.getAdditionalNotes().trim().isEmpty()) {
                document.add(new Paragraph("Additional Notes:", headerFont));
                document.add(new Paragraph(mc.getAdditionalNotes(), normalFont));
                document.add(new Paragraph(" ")); // Empty line
            }
            
            // Issue Date
            document.add(new Paragraph("Date of Issue: " + dateFormat.format(mc.getIssueDate()), normalFont));
            
            document.add(new Paragraph(" ")); // Empty line
            document.add(new Paragraph(" ")); // Empty line
            
            // Doctor Information
            document.add(new Paragraph("Doctor Information:", headerFont));
            document.add(new Paragraph("Name: Dr. " + (doctor != null ? doctor.getName() : "N/A"), normalFont));
            document.add(new Paragraph("Specialization: " + (doctor != null ? doctor.getSpecialization() : "N/A"), normalFont));
            
            document.add(new Paragraph(" ")); // Empty line
            document.add(new Paragraph(" ")); // Empty line
            
            // Signature line
            document.add(new Paragraph("_________________________", normalFont));
            document.add(new Paragraph("Doctor's Signature", smallFont));
            
            document.close();
            out.flush();
            out.close();
            
        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("Invalid appointment ID");
        } catch (DocumentException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("Error generating PDF");
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("Error generating medical certificate");
        }
    }
    
    /**
     * Calculate age from date of birth
     */
    private String calculateAge(Date dob) {
        if (dob == null) return "N/A";
        
        long ageInMillis = System.currentTimeMillis() - dob.getTime();
        long ageInYears = ageInMillis / (1000L * 60 * 60 * 24 * 365);
        
        return String.valueOf(ageInYears) + " years";
    }
    
    @Override
    public String getServletInfo() {
        return "MedicalCertificateServlet handles medical certificate operations";
    }
}
