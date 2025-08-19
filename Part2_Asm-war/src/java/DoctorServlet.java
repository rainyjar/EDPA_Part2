import java.io.BufferedReader;
import model.Doctor;
import model.DoctorFacade;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import javax.servlet.annotation.MultipartConfig;
import model.Customer;
import model.CustomerFacade;
import model.Appointment;
import model.AppointmentFacade;
import model.Feedback;
import model.FeedbackFacade;
import model.MedicalCertificateFacade;
import model.Payment;
import model.PaymentFacade;

@WebServlet("/DoctorServlet")
@MultipartConfig(fileSizeThreshold = 1024 * 1024, // 1MB
        maxFileSize = 1024 * 1024 * 5, // 5MB
        maxRequestSize = 1024 * 1024 * 10) // 10MB

public class DoctorServlet extends HttpServlet {

    @EJB
    private MedicalCertificateFacade medicalCertificateFacade;

    @EJB
    private DoctorFacade doctorFacade;
    
    @EJB
    private CustomerFacade customerFacade;
    
    @EJB
    private AppointmentFacade appointmentFacade;
    
    @EJB
    private FeedbackFacade feedbackFacade;
    
    @EJB
    private PaymentFacade paymentFacade;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        HttpSession session = request.getSession(false);
        
        // Check if it's a doctor-specific action
        Doctor loggedInDoctor = (session != null) ? (Doctor) session.getAttribute("doctor") : null;
        if (loggedInDoctor != null && "createPayment".equals(action)) {
            handleCreatePayment(request, response, loggedInDoctor);
            return;
        }
        
        // Manager actions
        if (!isManagerLoggedIn(request, response)) {
            return;
        }

        if ("register".equals(action)) {
            handleRegister(request, response);
        } else if ("update".equals(action)) {
            handleUpdate(request, response);
        } else if ("delete".equals(action)) {
            handleDelete(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        String action = request.getParameter("action");
        // Default behavior: check session and show appropriate list
        Customer loggedInCustomer = (session != null) ? (Customer) session.getAttribute("customer") : null;
        System.out.println("Doctor Servlet: " + loggedInCustomer);

        if (loggedInCustomer != null) {
            // Authenticated as customer, show team page
            List<Doctor> doctorList = doctorFacade.findAll();
            request.setAttribute("doctorList", doctorList);
            request.getRequestDispatcher("/customer/team.jsp").forward(request, response);
        }

        // Manager logic only for view/edit/delete
        if ("view".equals(action) || "edit".equals(action) || "delete".equals(action)) {
            if (!isManagerLoggedIn(request, response)) {
                return;
            }

            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Doctor doctor = doctorFacade.find(id);

                if (doctor == null) {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=doctor_not_found");
                    return;
                }

                if ("view".equals(action)) {
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/view_doc.jsp").forward(request, response);
                } else if ("edit".equals(action)) {
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/edit_doctor.jsp").forward(request, response);
                } else if ("delete".equals(action)) {
                    doctorFacade.remove(doctor);
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=doctor_deleted");
                }
            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=system_error");
            }
        }

        // Doctor-specific actions (when doctor is logged in)
        Doctor loggedInDoctor = (session != null) ? (Doctor) session.getAttribute("doctor") : null;
        if (loggedInDoctor != null && "patientRecords".equals(action)) {
            handlePatientRecords(request, response, loggedInDoctor);
            return;
        }
        if (loggedInDoctor != null && "issuePayment".equals(action)) {
            handleIssuePayment(request, response, loggedInDoctor);
            return;
        }
        if (loggedInDoctor != null && "generateMC".equals(action)) {
            handleGenerateMC(request, response, loggedInDoctor);
            return;
        }
    }

    private void handleRegister(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Doctor doctor = new Doctor();
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (!populateDoctorFromRequest(request, doctor, null)) {
            preserveFormData(request);
            request.setAttribute("doctor", doctor);
            request.getRequestDispatcher("/manager/register_doctor.jsp").forward(request, response);
            return;
        }
        doctorFacade.create(doctor);
        request.setAttribute("success", "Doctor registered successfully.");
        request.getRequestDispatcher("manager/register_doctor.jsp").forward(request, response);
    }

       private void handleUpdate(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            Doctor doctor = doctorFacade.find(id);
    
            if (doctor == null) {
                response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=doctor_not_found");
                return;
            }
    
            if (!populateDoctorFromRequest(request, doctor, doctor.getEmail())) {
                request.setAttribute("doctor", doctor);
                request.getRequestDispatcher("/DoctorServlet?action=edit&id=" + doctor.getId()).forward(request, response);
                return;
            }
    
            try {
                doctorFacade.edit(doctor);
                request.setAttribute("success", "Doctor updated successfully.");
                response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=doctor_updated");
            } catch (Exception e) {
                // Handle database constraint violations
                String errorMsg = e.getMessage().toLowerCase();
                if (errorMsg.contains("constraint") || errorMsg.contains("unique") || 
                    errorMsg.contains("duplicate") || errorMsg.contains("nric") || 
                    errorMsg.contains("ic")) {
                    
                    request.setAttribute("error", "This NRIC is already registered to another user");
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/DoctorServlet?action=edit&id=" + doctor.getId()).forward(request, response);
                } else {
                    throw e; // Re-throw if not a constraint violation
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=update_failed");
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        Doctor doctor = doctorFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (doctor != null) {
            doctorFacade.remove(doctor);
        }
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=staff_deleted");
    }

    private boolean populateDoctorFromRequest(HttpServletRequest request, Doctor doctor, String existingEmail) throws IOException, ServletException {
        String name = readFormField(request.getPart("name"));
        String email = readFormField(request.getPart("email"));
        String password = readFormField(request.getPart("password"));
        String phone = readFormField(request.getPart("phone"));
        String gender = readFormField(request.getPart("gender"));
        String dobStr = readFormField(request.getPart("dob"));
        String specialization = readFormField(request.getPart("specialization"));
        String nric = readFormField(request.getPart("nric"));
        String address = readFormField(request.getPart("address"));

        if (name.isEmpty() || email.isEmpty() || password.isEmpty() || phone.isEmpty() || gender == null || dobStr.isEmpty() || specialization.isEmpty() || nric.isEmpty() || address.isEmpty()) {
            request.setAttribute("error", "All fields are required.");
            return false;
        }

        if (!email.equals(existingEmail) && doctorFacade.searchEmail(email) != null) {
            request.setAttribute("error", "Email address is already registered.");
            return false;
        }

        // ADD THIS: Check if NRIC already exists (excluding current doctor)
        if (doctor.getId() != 0) {
            // Editing existing doctor - check if another doctor has this NRIC
            Doctor existingDoctorWithNric = doctorFacade.findByIc(nric);
            if (existingDoctorWithNric != null && existingDoctorWithNric.getId() != doctor.getId()) {
                request.setAttribute("error", "IC is already registered to another doctor.");
                return false;
            }
        } else {
            // New doctor - check if IC exists anywhere
            Doctor existingDoctorWithNric = doctorFacade.findByIc(nric);
            if (existingDoctorWithNric != null) {
                request.setAttribute("error", "IC is already registered to another doctor.");
                return false;
            }
        }

        try {
            doctor.setName(name);
            doctor.setEmail(email);
            doctor.setPassword(password);
            doctor.setPhone(phone);
            doctor.setGender(gender);
            doctor.setDob(Date.valueOf(dobStr));
            doctor.setSpecialization(specialization);
            doctor.setIc(nric);
            doctor.setAddress(address);

        } catch (Exception e) {
            request.setAttribute("error", "Invalid input format.");
            return false;
        }

        // Handle profile picture
        Part file = request.getPart("profilePic");
        try {
            if (file != null && file.getSize() > 0) {
                String uploadedFileName = UploadImage.uploadImage(file, "profile_pictures");
                doctor.setProfilePic(uploadedFileName);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
            return false;
        }

        return true;
    }

    private void preserveFormData(HttpServletRequest request) throws IOException, ServletException {
        Doctor doctor = new Doctor();
        doctor.setName(readFormField(request.getPart("name")));
        doctor.setEmail(readFormField(request.getPart("email")));
        doctor.setPassword(readFormField(request.getPart("password")));
        doctor.setPhone(readFormField(request.getPart("phone")));
        doctor.setGender(readFormField(request.getPart("gender")));
        doctor.setSpecialization(readFormField(request.getPart("specialization")));
        doctor.setIc(readFormField(request.getPart("nric")));
        doctor.setAddress(readFormField(request.getPart("address")));

        String dobStr = readFormField(request.getPart("dob"));
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                doctor.setDob(Date.valueOf(dobStr));
            } catch (Exception ignored) {
            }
        }

        request.setAttribute("doctor", doctor);
    }

    private String readFormField(Part part) throws IOException {
        if (part == null) {
            return "";
        }
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(part.getInputStream(), StandardCharsets.UTF_8))) {
            return reader.lines().collect(Collectors.joining("\n")).trim();
        }
    }

    private boolean isManagerLoggedIn(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("manager") == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return false;
            }
            return true;
        } catch (IllegalStateException e) {
            // Already committed response (e.g., forward was called), can't redirect
            System.out.println("Warning: Response already committed. Skipping redirect.");
            return false;
        }
    }

    private void handlePatientRecords(HttpServletRequest request, HttpServletResponse response, Doctor loggedInDoctor) 
            throws ServletException, IOException {
        try {
            // Get search parameters
            String searchQuery = request.getParameter("searchQuery");
            String customerIdParam = request.getParameter("customerId");
            
            List<Customer> patients = customerFacade.findAll();
            List<Appointment> doctorAppointments = appointmentFacade.findAll();
            
            // Filter appointments for this doctor to get patients (unique only)
            List<Customer> doctorPatients = new java.util.ArrayList<>();
            java.util.Set<Integer> seenPatientIds = new java.util.HashSet<>();
            
            for (Appointment apt : doctorAppointments) {
                if (apt.getDoctor() != null && apt.getDoctor().getId() == loggedInDoctor.getId()) {
                    Customer patient = apt.getCustomer();
                    if (patient != null && !seenPatientIds.contains(patient.getId())) {
                        doctorPatients.add(patient);
                        seenPatientIds.add(patient.getId());
                    }
                }
            }
            
            // If searching for a specific customer
            if (customerIdParam != null && !customerIdParam.trim().isEmpty()) {
                try {
                    int customerId = Integer.parseInt(customerIdParam);
                    Customer selectedPatient = customerFacade.find(customerId);
                    
                    if (selectedPatient != null) {
                        // Get medical history for this patient
                        List<Appointment> patientAppointments = new java.util.ArrayList<>();
                        List<Feedback> patientFeedbacks = new java.util.ArrayList<>();
                        
                        for (Appointment apt : doctorAppointments) {
                            if (apt.getCustomer() != null && apt.getCustomer().getId() == customerId) {
                                patientAppointments.add(apt);
                            }
                        }
                        
                        // Get feedbacks for this patient
                        List<Feedback> allFeedbacks = feedbackFacade.findAll();
                        for (Feedback feedback : allFeedbacks) {
                            if (feedback.getFromCustomer() != null && 
                                feedback.getFromCustomer().getId() == customerId) {
                                patientFeedbacks.add(feedback);
                            }
                        }
                        
                        request.setAttribute("selectedPatient", selectedPatient);
                        request.setAttribute("patientAppointments", patientAppointments);
                        request.setAttribute("patientFeedbacks", patientFeedbacks);
                    }
                } catch (NumberFormatException e) {
                    request.setAttribute("error", "Invalid patient ID");
                }
            }
            
            // Filter patients based on search query
            if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                List<Customer> filteredPatients = new java.util.ArrayList<>();
                String query = searchQuery.toLowerCase();
                
                for (Customer patient : doctorPatients) {
                    if (patient.getName().toLowerCase().contains(query) ||
                        patient.getEmail().toLowerCase().contains(query) ||
                        (patient.getIc() != null && patient.getIc().contains(query))) {
                        filteredPatients.add(patient);
                    }
                }
                doctorPatients = filteredPatients;
            }
            
            request.setAttribute("patients", doctorPatients);
            request.setAttribute("allDoctorAppointments", doctorAppointments);
            request.setAttribute("loggedInDoctor", loggedInDoctor);
            request.setAttribute("searchQuery", searchQuery);
            
            request.getRequestDispatcher("/doctor/patient_records.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error loading patient records: " + e.getMessage());
            request.getRequestDispatcher("/doctor/patient_records.jsp").forward(request, response);
        }
    }
    
    /**
     * Handle displaying the issue payment page for doctors
     */
    private void handleIssuePayment(HttpServletRequest request, HttpServletResponse response, Doctor loggedInDoctor)
            throws ServletException, IOException {
        try {
            // Get doctor's completed appointments that don't have payments yet
            List<Appointment> completedAppointments = appointmentFacade.findByDoctorAndStatus(loggedInDoctor.getId(), "completed");
            
            // Filter out appointments that already have payments
            List<Appointment> appointmentsNeedingPaymentAmount = completedAppointments.stream()
                .filter(appointment -> {
                    try {
                        Payment existingPayment = paymentFacade.findByAppointmentId(appointment.getId());
                        return existingPayment == null || existingPayment.getAmount() <= 0;
                    } catch (Exception e) {
                        return true; // Include in case of error to be safe
                    }
                })
                .collect(Collectors.toList());
            
            request.setAttribute("appointments", appointmentsNeedingPaymentAmount);
            request.setAttribute("doctor", loggedInDoctor);
            
            // Format date and time
            java.text.SimpleDateFormat dateFormat = new java.text.SimpleDateFormat("dd MMM yyyy");
            java.text.SimpleDateFormat timeFormat = new java.text.SimpleDateFormat("HH:mm");
            request.setAttribute("dateFormat", dateFormat);
            request.setAttribute("timeFormat", timeFormat);
            
            request.getRequestDispatcher("/doctor/issue_payment.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error loading appointments: " + e.getMessage());
            request.getRequestDispatcher("/doctor/issue_payment.jsp").forward(request, response);
        }
    }
    
    private void handleCreatePayment(HttpServletRequest request, HttpServletResponse response, Doctor loggedInDoctor)
            throws ServletException, IOException {
        try {
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            double amount = Double.parseDouble(request.getParameter("amount"));
            
            // Validate the amount
            if (amount <= 0) {
                request.setAttribute("error", "Payment amount must be greater than 0.");
                handleIssuePayment(request, response, loggedInDoctor);
                return;
            }
            
            // Find the existing payment for this appointment
            Payment existingPayment = paymentFacade.findByAppointmentId(appointmentId);
            
            if (existingPayment != null) {
                // Update the existing payment with the amount
                existingPayment.setAmount(amount);
                paymentFacade.edit(existingPayment);
                
                request.setAttribute("success", "Payment amount has been set successfully.");
            } else {
                // This should rarely happen (only if payment record wasn't created at completion)
                Appointment appointment = appointmentFacade.find(appointmentId);
                
                if (appointment == null) {
                    request.setAttribute("error", "Appointment not found.");
                    handleIssuePayment(request, response, loggedInDoctor);
                    return;
                }
                
                // Create a new payment record as fallback
                Payment payment = new Payment();
                payment.setAppointment(appointment);
                payment.setAmount(amount);
                payment.setStatus("pending");
                payment.setPaymentDate(null);
                paymentFacade.create(payment);
                
                request.setAttribute("success", "Payment record created successfully.");
            }
            
            // Redirect back to the payment page
            handleIssuePayment(request, response, loggedInDoctor);
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid appointment ID or payment amount.");
            handleIssuePayment(request, response, loggedInDoctor);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error creating payment: " + e.getMessage());
            handleIssuePayment(request, response, loggedInDoctor);
        }
    }
    
    /**
     * Handle displaying the generate MC page for doctors
     */
    private void handleGenerateMC(HttpServletRequest request, HttpServletResponse response, Doctor loggedInDoctor)
        throws ServletException, IOException {
        try {
            // Get doctor's completed appointments
            List<Appointment> completedAppointments = appointmentFacade.findByDoctorAndStatus(loggedInDoctor.getId(), "completed");
            
            // Add MC status information to each appointment
            Map<Integer, Boolean> mcExistsMap = new HashMap<>();
            for (Appointment appointment : completedAppointments) {
                boolean hasMC = medicalCertificateFacade.existsByAppointmentId(appointment.getId());
                mcExistsMap.put(appointment.getId(), hasMC);
            }
            
            request.setAttribute("completedAppointments", completedAppointments);
            request.setAttribute("mcExistsMap", mcExistsMap);
            request.setAttribute("doctor", loggedInDoctor);
                
            // Check for success/error messages from parameters (for redirects)
            String successMsg = request.getParameter("success");
            String errorMsg = request.getParameter("error");
            if (successMsg != null) {
                request.setAttribute("success", successMsg);
            }
            if (errorMsg != null) {
                request.setAttribute("error", errorMsg);
            }
            
            request.getRequestDispatcher("/doctor/generate_mc.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error loading completed appointments: " + e.getMessage());
            request.getRequestDispatcher("/doctor/generate_mc.jsp").forward(request, response);
        }
    }

    @Override
    public String getServletInfo() {
        return "DoctorServlet - Handles CRUD operations for doctors";
    }
}
