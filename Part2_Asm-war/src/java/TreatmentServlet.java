
import java.io.IOException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Set;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.Appointment;
import model.AppointmentFacade;
import model.Doctor;
import model.DoctorFacade;
import model.Prescription;
import model.PrescriptionFacade;
import model.Treatment;
import model.TreatmentFacade;

@WebServlet(urlPatterns = {"/TreatmentServlet"})
@MultipartConfig(maxFileSize = 5 * 1024 * 1024) // 5MB max file size
public class TreatmentServlet extends HttpServlet {

    @EJB
    private PrescriptionFacade prescriptionFacade;

    @EJB
    private TreatmentFacade treatmentFacade;

    @EJB
    private AppointmentFacade appointmentFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        String idParam = request.getParameter("id");
        HttpSession session = request.getSession();

        // Check if user is logged in as doctor for management actions
        Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");

        if ("viewAll".equalsIgnoreCase(action)) {
            List<Treatment> treatmentList = treatmentFacade.findAll();
            request.setAttribute("treatmentList", treatmentList);

            // Check if request is from counter staff
            String role = request.getParameter("role");
            if ("staff".equalsIgnoreCase(role)) {
                request.getRequestDispatcher("/counter_staff/view_treatments.jsp").forward(request, response);
            } else {
                request.getRequestDispatcher("/customer/treatment.jsp").forward(request, response);
            }

        } else if ("viewDetail".equalsIgnoreCase(action) && idParam != null) {
            try {
                int id = Integer.parseInt(idParam);
                Treatment treatment = treatmentFacade.find(id);
                List<Prescription> prescriptions = prescriptionFacade.findByTreatmentId(id);
                request.setAttribute("treatment", treatment);
                request.setAttribute("prescriptions", prescriptions);

                // Check if request is from counter staff
                String role = request.getParameter("role");
                if ("staff".equalsIgnoreCase(role)) {
                    request.getRequestDispatcher("/counter_staff/treatment_description.jsp").forward(request, response);
                } else {
                    request.getRequestDispatcher("/customer/treatment_description.jsp").forward(request, response);
                }
            } catch (NumberFormatException e) {
                request.setAttribute("error", "Invalid treatment ID.");

                // Check role for error redirect
                String role = request.getParameter("role");
                if ("staff".equalsIgnoreCase(role)) {
                    request.getRequestDispatcher("/counter_staff/view_treatments.jsp").forward(request, response);
                } else {
                    request.getRequestDispatcher("/customer/treatment.jsp").forward(request, response);
                }
            }

        } else if ("manage".equalsIgnoreCase(action)) {
            // Doctor management page - show all treatments with CRUD options
            if (loggedInDoctor == null) {
                response.sendRedirect("login.jsp");
                return;
            }

            // Get search parameters
            String treatmentSearch = request.getParameter("treatmentSearch");
            String prescriptionSearch = request.getParameter("prescriptionSearch");
            String chargeFilter = request.getParameter("chargeFilter");
            String prescriptionCountFilter = request.getParameter("prescriptionCount");

            List<Treatment> treatmentList = treatmentFacade.findAll();

            // Get accurate prescription counts for each treatment
            java.util.Map<Integer, Integer> prescriptionCounts = new java.util.HashMap<>();
            for (Treatment treatment : treatmentList) {
                List<Prescription> prescriptions = prescriptionFacade.findByTreatmentId(treatment.getId());
                prescriptionCounts.put(treatment.getId(), prescriptions.size());
            }

            // Apply server-side filtering if needed (optional - client-side filtering is already implemented)
            if (treatmentSearch != null && !treatmentSearch.trim().isEmpty()) {
                // You can implement server-side search here if needed
                // For now, we'll rely on client-side filtering
            }

            request.setAttribute("treatmentList", treatmentList);
            request.setAttribute("prescriptionCounts", prescriptionCounts);
            request.setAttribute("treatmentSearch", treatmentSearch);
            request.setAttribute("prescriptionSearch", prescriptionSearch);
            request.setAttribute("chargeFilter", chargeFilter);
            request.setAttribute("prescriptionCountFilter", prescriptionCountFilter);
            request.getRequestDispatcher("/doctor/manage_treatments.jsp").forward(request, response);

        } else if ("createForm".equalsIgnoreCase(action)) {
            // Show form to create new treatment
            if (loggedInDoctor == null) {
                response.sendRedirect("login.jsp");
                return;
            }

            // Load all doctors for assignment
            List<Doctor> allDoctors = doctorFacade.findAll();
            request.setAttribute("allDoctors", allDoctors);

            request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);

        } else if ("editForm".equalsIgnoreCase(action) && idParam != null) {
            // Show form to edit existing treatment
            if (loggedInDoctor == null) {
                response.sendRedirect("login.jsp");
                return;
            }
            try {
                int id = Integer.parseInt(idParam);
                Treatment treatment = treatmentFacade.find(id);
                List<Prescription> prescriptions = prescriptionFacade.findByTreatmentId(id);

                // Load all doctors for assignment
                List<Doctor> allDoctors = doctorFacade.findAll();

                request.setAttribute("treatment", treatment);
                request.setAttribute("prescriptions", prescriptions);
                request.setAttribute("allDoctors", allDoctors);
                request.getRequestDispatcher("/doctor/edit_treatment.jsp").forward(request, response);
            } catch (NumberFormatException e) {
                request.setAttribute("error", "Invalid treatment ID.");
                response.sendRedirect("TreatmentServlet?action=manage");
            }

        } else if ("deletePrescription".equalsIgnoreCase(action)) {
            // Handle prescription deletion
            if (loggedInDoctor == null) {
                response.sendRedirect("login.jsp");
                return;
            }
            try {
                int prescriptionId = Integer.parseInt(request.getParameter("prescriptionId"));
                int treatmentId = Integer.parseInt(request.getParameter("treatmentId"));

                Prescription prescription = prescriptionFacade.find(prescriptionId);
                if (prescription != null) {
                    String conditionName = prescription.getConditionName();
                    String medicationName = prescription.getMedicationName();

                    prescriptionFacade.remove(prescription);

                    String successMessage = "Prescription deleted successfully";
                    response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId + "&prescriptionSuccess="
                            + java.net.URLEncoder.encode(successMessage, "UTF-8"));
                } else {
                    response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId + "&prescriptionError="
                            + java.net.URLEncoder.encode("Prescription not found.", "UTF-8"));
                }
            } catch (NumberFormatException e) {
                response.sendRedirect("TreatmentServlet?action=manage&error="
                        + java.net.URLEncoder.encode("Invalid prescription or treatment ID.", "UTF-8"));
            } catch (Exception e) {
                String treatmentId = request.getParameter("treatmentId");
                response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId + "&prescriptionError="
                        + java.net.URLEncoder.encode("Error deleting prescription: " + e.getMessage(), "UTF-8"));
            }

        } else if ("myTasks".equalsIgnoreCase(action)) {
            // Show doctor's approved appointments only (tasks to be completed)
            if (loggedInDoctor == null) {
                response.sendRedirect("login.jsp");
                return;
            }

            // Get only approved appointments for this doctor
            List<Appointment> approvedAppointments = appointmentFacade.findByDoctorAndStatus(loggedInDoctor.getId(), "approved");

            // Handle search and filter parameters (no status filter needed here)
            String searchQuery = request.getParameter("searchQuery");
            String dateFilter = request.getParameter("dateFilter");

            // Filter for today's appointments if dateFilter=today
            if ("today".equalsIgnoreCase(dateFilter)) {
                List<Appointment> todayAppointments = new ArrayList<>();
                java.util.Date today = new java.util.Date();
                java.text.SimpleDateFormat dateFormat = new java.text.SimpleDateFormat("yyyy-MM-dd");
                String todayStr = dateFormat.format(today);

                for (Appointment apt : approvedAppointments) {
                    if (apt.getAppointmentDate() != null) {
                        String aptDateStr = dateFormat.format(apt.getAppointmentDate());
                        if (aptDateStr.equals(todayStr)) {
                            todayAppointments.add(apt);
                        }
                    }
                }

                // Replace the full list with the filtered today list
                approvedAppointments = todayAppointments;
                System.out.println("Filtered to " + approvedAppointments.size() + " appointments for today: " + todayStr);
            }

            request.setAttribute("appointments", approvedAppointments);
            request.setAttribute("searchQuery", searchQuery);
            request.setAttribute("dateFilter", dateFilter);
            request.getRequestDispatcher("/doctor/my_tasks.jsp").forward(request, response);

        } else if ("viewAppointmentHistory".equalsIgnoreCase(action)) {
            // Show all appointment history with all statuses
            if (loggedInDoctor == null) {
                response.sendRedirect("login.jsp");
                return;
            }

            // Get all appointments for this doctor (all statuses)
            List<Appointment> approvedAppointments = appointmentFacade.findByDoctorAndStatus(loggedInDoctor.getId(), "approved");
            List<Appointment> completedAppointments = appointmentFacade.findByDoctorAndStatus(loggedInDoctor.getId(), "completed");
            List<Appointment> pendingAppointments = appointmentFacade.findByDoctorAndStatus(loggedInDoctor.getId(), "pending");
            List<Appointment> cancelledAppointments = appointmentFacade.findByDoctorAndStatus(loggedInDoctor.getId(), "cancelled");

            // Combine all appointments
            List<Appointment> allAppointments = new ArrayList<>();
            allAppointments.addAll(approvedAppointments);
            allAppointments.addAll(completedAppointments);
            allAppointments.addAll(pendingAppointments);
            allAppointments.addAll(cancelledAppointments);

            // Handle search and filter parameters
            String searchQuery = request.getParameter("searchQuery");
            String statusFilter = request.getParameter("statusFilter");
            String dateFilter = request.getParameter("dateFilter");

            request.setAttribute("appointments", allAppointments);
            request.setAttribute("searchQuery", searchQuery);
            request.setAttribute("statusFilter", statusFilter);
            request.setAttribute("dateFilter", dateFilter);
            request.getRequestDispatcher("/doctor/view_apt_history.jsp").forward(request, response);

        } else if ("complete".equalsIgnoreCase(action)) {
            try {
                int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
                Appointment appointment = appointmentFacade.find(appointmentId);
                
                if (appointment == null) {
                    response.sendRedirect(request.getContextPath() + "/TreatmentServlet?action=myTasks&error=appointment_not_found");
                    return;
                }

                // Get appointment date and current date
                Date apptDate = appointment.getAppointmentDate();
                if (apptDate == null) {
                    response.sendRedirect(request.getContextPath() + "/TreatmentServlet?action=myTasks&error=invalid_appointment_datetime");
                    return;
                }
                
                // Compare just the date portion (ignore time)
                Calendar apptCal = Calendar.getInstance();
                apptCal.setTime(apptDate);
                
                Calendar todayCal = Calendar.getInstance();
                
                // Check if same date (year, month, day match)
                boolean isSameDay = (apptCal.get(Calendar.YEAR) == todayCal.get(Calendar.YEAR) &&
                                    apptCal.get(Calendar.MONTH) == todayCal.get(Calendar.MONTH) &&
                                    apptCal.get(Calendar.DAY_OF_MONTH) == todayCal.get(Calendar.DAY_OF_MONTH));
                
                // Only allow completion if it's the same day or appointment date is in the past
                if (!isSameDay && apptDate.after(new Date())) {
                    response.sendRedirect(request.getContextPath() + "/TreatmentServlet?action=myTasks&error=complete_not_allowed");
                    return;
                }

                // Allowed: proceed with completing appointment (existing code)
                appointment.setStatus("completed");
                // ... any other operations (create treatment record etc) ...
                appointmentFacade.edit(appointment);

                response.sendRedirect(request.getContextPath() + "/TreatmentServlet?action=myTasks&success=appointment_completed");

            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/TreatmentServlet?action=myTasks&error=invalid_parameters");
            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/TreatmentServlet?action=myTasks&error=complete_failed");
            }

        } else {
            response.sendRedirect("error.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        HttpSession session = request.getSession();
        Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");

        // Check if user is logged in as doctor for management actions
        if (loggedInDoctor == null && !"viewAll".equals(action) && !"viewDetail".equals(action)) {
            response.sendRedirect("login.jsp");
            return;
        }

        if ("create".equalsIgnoreCase(action)) {
            handleCreateTreatment(request, response);

        } else if ("update".equalsIgnoreCase(action)) {
            handleUpdateTreatment(request, response);

        } else if ("delete".equalsIgnoreCase(action)) {
            handleDeleteTreatment(request, response);

        } else if ("addPrescription".equalsIgnoreCase(action)) {
            handleAddPrescription(request, response);

        } else if ("updatePrescription".equalsIgnoreCase(action)) {
            handleUpdatePrescription(request, response);

        } else if ("completeAppointment".equalsIgnoreCase(action)) {
            handleCompleteAppointment(request, response);

        } else {
            response.sendRedirect("TreatmentServlet?action=manage");
        }
    }

    private void handleCreateTreatment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            String name = request.getParameter("name");
            String shortDesc = request.getParameter("shortDesc");
            String longDesc = request.getParameter("longDesc");
            String baseChargeStr = request.getParameter("baseCharge");
            String followUpChargeStr = request.getParameter("followUpCharge");

            // Handle treatment image (file upload)
            String treatmentPicPath = "";
            try {
                Part treatmentPicPart = request.getPart("treatmentPic");
                if (treatmentPicPart != null && treatmentPicPart.getSize() > 0) {
                    String uploadedFileName = UploadImage.uploadImage(treatmentPicPart, "treatment");
                    if (uploadedFileName != null) {
                        treatmentPicPath = uploadedFileName;
                    } else {
                        request.setAttribute("error", "Failed to upload treatment image.");
                        request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                        return;
                    }
                } else {
                    request.setAttribute("error", "Treatment image is required.");
                    request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                    return;
                }
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Treatment image upload failed: " + e.getMessage());
                request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                return;
            }

            // Validate required fields
            if (name == null || name.trim().isEmpty()) {
                request.setAttribute("error", "Treatment name is required.");
                request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                return;
            }

            if (shortDesc == null || shortDesc.trim().isEmpty()) {
                request.setAttribute("error", "Short description is required.");
                request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                return;
            }

            if (baseChargeStr == null || baseChargeStr.trim().isEmpty()) {
                request.setAttribute("error", "Base consultation charge is required.");
                request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                return;
            }

            if (followUpChargeStr == null || followUpChargeStr.trim().isEmpty()) {
                request.setAttribute("error", "Follow-up charge is required.");
                request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                return;
            }

            // Parse numeric values
            double baseCharge, followUpCharge;
            try {
                baseCharge = Double.parseDouble(baseChargeStr);
                followUpCharge = Double.parseDouble(followUpChargeStr);
            } catch (NumberFormatException e) {
                request.setAttribute("error", "Invalid numeric values for charges.");
                request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                return;
            }

            // Validate charge values
            if (baseCharge < 0 || followUpCharge < 0) {
                request.setAttribute("error", "Charges cannot be negative.");
                request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                return;
            }

            // Create new treatment
            Treatment treatment = new Treatment();
            treatment.setName(name.trim());
            treatment.setShortDescription(shortDesc.trim());
            treatment.setLongDescription(longDesc != null ? longDesc.trim() : "");
            treatment.setBaseConsultationCharge(baseCharge);
            treatment.setFollowUpCharge(followUpCharge);
            treatment.setTreatmentPic(treatmentPicPath != null ? treatmentPicPath.trim() : "");

            // Handle doctor assignments
            String[] assignedDoctorIds = request.getParameterValues("assignedDoctors");
            if (assignedDoctorIds == null || assignedDoctorIds.length == 0) {
                request.setAttribute("error", "At least one doctor must be assigned to the treatment.");
                // Load all doctors again for the form
                List<Doctor> allDoctors = doctorFacade.findAll();
                request.setAttribute("allDoctors", allDoctors);
                request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                return;
            }

            treatmentFacade.create(treatment);

            // Assign doctors to treatment
            Set<Doctor> assignedDoctors = new java.util.HashSet<>();
            for (String doctorIdStr : assignedDoctorIds) {
                try {
                    int doctorId = Integer.parseInt(doctorIdStr);
                    Doctor doctor = doctorFacade.find(doctorId);
                    if (doctor != null) {
                        assignedDoctors.add(doctor);
                    }
                } catch (NumberFormatException e) {
                    System.err.println("Invalid doctor ID: " + doctorIdStr);
                }
            }

            // Set the doctors and update the treatment
            treatment.setDoctors(assignedDoctors);
            treatmentFacade.edit(treatment);

            // Handle prescriptions if provided
            String[] conditionNames = request.getParameterValues("conditionName");
            String[] medicationNames = request.getParameterValues("medicationName");

            int prescriptionCount = 0;
            if (conditionNames != null && medicationNames != null) {
                for (int i = 0; i < Math.min(conditionNames.length, medicationNames.length); i++) {
                    String condition = conditionNames[i];
                    String medication = medicationNames[i];

                    // Validate prescription fields - both must be filled or both must be empty
                    boolean hasCondition = condition != null && !condition.trim().isEmpty();
                    boolean hasMedication = medication != null && !medication.trim().isEmpty();

                    if (hasCondition || hasMedication) {
                        // If either field has content, both must have content
                        if (!hasCondition || !hasMedication) {
                            String errorMessage = "Invalid prescription at row " + (i + 1) + ": Both condition name and medication name are required. Please fill both fields or leave both empty.";
                            request.setAttribute("error", errorMessage);
                            request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                            return;
                        }

                        // Both fields have content - validate length
                        if (condition.trim().length() < 2) {
                            String errorMessage = "Condition name at row " + (i + 1) + " must be at least 2 characters long.";
                            request.setAttribute("error", errorMessage);
                            request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                            return;
                        }

                        if (medication.trim().length() < 2) {
                            String errorMessage = "Medication name at row " + (i + 1) + " must be at least 2 characters long.";
                            request.setAttribute("error", errorMessage);
                            request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
                            return;
                        }

                        Prescription prescription = new Prescription();
                        prescription.setConditionName(condition.trim());
                        prescription.setMedicationName(medication.trim());
                        prescription.setTreatment(treatment);

                        prescriptionFacade.create(prescription);
                        prescriptionCount++;
                    }
                }
            }

            String successMessage = "Treatment created successfully with " + assignedDoctors.size() + " doctor(s) and " + prescriptionCount + " prescriptions.";
            request.setAttribute("success", successMessage);
            request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            e.printStackTrace();
            request.setAttribute("error", "Invalid numeric values provided.");
            // Load all doctors again for the form
            List<Doctor> allDoctors = doctorFacade.findAll();
            request.setAttribute("allDoctors", allDoctors);
            request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error creating treatment: " + e.getMessage());
            // Load all doctors again for the form
            List<Doctor> allDoctors = doctorFacade.findAll();
            request.setAttribute("allDoctors", allDoctors);
            request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
        }
    }

    private void handleUpdateTreatment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            int id = Integer.parseInt(request.getParameter("id"));
            Treatment treatment = treatmentFacade.find(id);

            if (treatment != null) {
                treatment.setName(request.getParameter("name"));
                treatment.setShortDescription(request.getParameter("shortDesc"));
                treatment.setLongDescription(request.getParameter("longDesc"));
                treatment.setBaseConsultationCharge(Double.parseDouble(request.getParameter("baseCharge")));
                treatment.setFollowUpCharge(Double.parseDouble(request.getParameter("followUpCharge")));

                // Handle treatment image update (optional for edit)
                try {
                    Part treatmentPicPart = request.getPart("treatmentPic");
                    if (treatmentPicPart != null && treatmentPicPart.getSize() > 0) {
                        String uploadedFileName = UploadImage.uploadImage(treatmentPicPart, "treatment");
                        if (uploadedFileName != null) {
                            treatment.setTreatmentPic(uploadedFileName);
                        }
                    }
                    // Keep existing image if no new file uploaded
                } catch (Exception e) {
                    e.printStackTrace();
                    // Don't fail the entire update if image upload fails
                }

                // Handle doctor assignments
                String[] assignedDoctorIds = request.getParameterValues("assignedDoctors");
                if (assignedDoctorIds == null || assignedDoctorIds.length == 0) {
                    request.setAttribute("error", "At least one doctor must be assigned to the treatment.");
                    request.setAttribute("treatment", treatment);
                    List<Prescription> prescriptions = prescriptionFacade.findByTreatmentId(id);
                    request.setAttribute("prescriptions", prescriptions);
                    // Load all doctors again for the form
                    List<Doctor> allDoctors = doctorFacade.findAll();
                    request.setAttribute("allDoctors", allDoctors);
                    request.getRequestDispatcher("/doctor/edit_treatment.jsp").forward(request, response);
                    return;
                }

                // Update doctor assignments
                Set<Doctor> assignedDoctors = new java.util.HashSet<>();
                for (String doctorIdStr : assignedDoctorIds) {
                    try {
                        int doctorId = Integer.parseInt(doctorIdStr);
                        Doctor doctor = doctorFacade.find(doctorId);
                        if (doctor != null) {
                            assignedDoctors.add(doctor);
                        }
                    } catch (NumberFormatException e) {
                        System.err.println("Invalid doctor ID: " + doctorIdStr);
                    }
                }

                // Set the doctors
                treatment.setDoctors(assignedDoctors);

                treatmentFacade.edit(treatment);

                // Handle new prescriptions if provided
                String[] conditionNames = request.getParameterValues("conditionName");
                String[] medicationNames = request.getParameterValues("medicationName");

                int newPrescriptionCount = 0;
                if (conditionNames != null && medicationNames != null) {
                    for (int i = 0; i < Math.min(conditionNames.length, medicationNames.length); i++) {
                        String condition = conditionNames[i];
                        String medication = medicationNames[i];

                        // Validate prescription fields - both must be filled or both must be empty
                        boolean hasCondition = condition != null && !condition.trim().isEmpty();
                        boolean hasMedication = medication != null && !medication.trim().isEmpty();

                        if (hasCondition || hasMedication) {
                            // If either field has content, both must have content
                            if (!hasCondition || !hasMedication) {
                                String errorMessage = "Invalid prescription at row " + (i + 1) + ": Both condition name and medication name are required. Please fill both fields or leave both empty.";
                                request.setAttribute("error", errorMessage);
                                request.setAttribute("treatment", treatment);
                                request.setAttribute("prescriptions", prescriptionFacade.findByTreatmentId(id));
                                request.getRequestDispatcher("/doctor/edit_treatment.jsp").forward(request, response);
                                return;
                            }

                            // Both fields have content - validate length
                            if (condition.trim().length() < 2) {
                                String errorMessage = "Condition name at row " + (i + 1) + " must be at least 2 characters long.";
                                request.setAttribute("error", errorMessage);
                                request.setAttribute("treatment", treatment);
                                request.setAttribute("prescriptions", prescriptionFacade.findByTreatmentId(id));
                                request.getRequestDispatcher("/doctor/edit_treatment.jsp").forward(request, response);
                                return;
                            }

                            if (medication.trim().length() < 2) {
                                String errorMessage = "Medication name at row " + (i + 1) + " must be at least 2 characters long.";
                                request.setAttribute("error", errorMessage);
                                request.setAttribute("treatment", treatment);
                                request.setAttribute("prescriptions", prescriptionFacade.findByTreatmentId(id));
                                request.getRequestDispatcher("/doctor/edit_treatment.jsp").forward(request, response);
                                return;
                            }

                            Prescription prescription = new Prescription();
                            prescription.setConditionName(condition.trim());
                            prescription.setMedicationName(medication.trim());
                            prescription.setTreatment(treatment);

                            prescriptionFacade.create(prescription);
                            newPrescriptionCount++;
                        }
                    }
                }

                String successMessage = "Treatment updated successfully with " + assignedDoctors.size() + " doctor(s) assigned";
                if (newPrescriptionCount > 0) {
                    successMessage += " and " + newPrescriptionCount + " new prescription" + (newPrescriptionCount > 1 ? "s" : "") + " added";
                }
                successMessage += ".";

                // Redirect with success message
                response.sendRedirect("TreatmentServlet?action=editForm&id=" + id + "&success="
                        + java.net.URLEncoder.encode(successMessage, "UTF-8"));
            } else {
                response.sendRedirect("TreatmentServlet?action=editForm&id=" + id + "&error="
                        + java.net.URLEncoder.encode("Treatment not found.", "UTF-8"));
            }

        } catch (NumberFormatException e) {
            e.printStackTrace();
            String treatmentId = request.getParameter("id");
            response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId + "&error="
                    + java.net.URLEncoder.encode("Invalid treatment ID or numeric values.", "UTF-8"));
        } catch (Exception e) {
            e.printStackTrace();
            String treatmentId = request.getParameter("id");
            response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId + "&error="
                    + java.net.URLEncoder.encode("Error updating treatment: " + e.getMessage(), "UTF-8"));
        }
    }

    private void handleDeleteTreatment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            Treatment treatment = treatmentFacade.find(id);

            if (treatment != null) {
                // First delete all associated prescriptions
                List<Prescription> prescriptions = prescriptionFacade.findByTreatmentId(id);
                for (Prescription prescription : prescriptions) {
                    prescriptionFacade.remove(prescription);
                }

                // Then delete the treatment
                treatmentFacade.remove(treatment);
                request.setAttribute("success", "Treatment and associated prescriptions deleted successfully.");
            } else {
                request.setAttribute("error", "Treatment not found.");
            }

        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid treatment ID.");
        } catch (Exception e) {
            request.setAttribute("error", "Error deleting treatment: " + e.getMessage());
        }

        response.sendRedirect("TreatmentServlet?action=manage");
    }

    private void handleAddPrescription(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            int treatmentId = Integer.parseInt(request.getParameter("treatmentId"));
            String conditionName = request.getParameter("conditionName");
            String medicationName = request.getParameter("medicationName");

            Treatment treatment = treatmentFacade.find(treatmentId);

            if (treatment != null && conditionName != null && !conditionName.trim().isEmpty()
                    && medicationName != null && !medicationName.trim().isEmpty()) {

                Prescription prescription = new Prescription();
                prescription.setConditionName(conditionName.trim());
                prescription.setMedicationName(medicationName.trim());
                prescription.setTreatment(treatment);

                prescriptionFacade.create(prescription);
                request.setAttribute("success", "Prescription added successfully.");
            } else {
                request.setAttribute("error", "Invalid data provided for prescription.");
            }

            response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId);

        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid treatment ID.");
            response.sendRedirect("TreatmentServlet?action=manage");
        } catch (Exception e) {
            request.setAttribute("error", "Error adding prescription: " + e.getMessage());
            response.sendRedirect("TreatmentServlet?action=manage");
        }
    }

    private void handleUpdatePrescription(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            int prescriptionId = Integer.parseInt(request.getParameter("prescriptionId"));
            int treatmentId = Integer.parseInt(request.getParameter("treatmentId"));
            String conditionName = request.getParameter("conditionName");
            String medicationName = request.getParameter("medicationName");

            Prescription prescription = prescriptionFacade.find(prescriptionId);

            if (prescription != null && conditionName != null && !conditionName.trim().isEmpty()
                    && medicationName != null && !medicationName.trim().isEmpty()) {

                prescription.setConditionName(conditionName.trim());
                prescription.setMedicationName(medicationName.trim());

                prescriptionFacade.edit(prescription);

                String successMessage = "Prescription updated successfully";
                response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId + "&prescriptionSuccess="
                        + java.net.URLEncoder.encode(successMessage, "UTF-8"));
            } else {
                response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId + "&prescriptionError="
                        + java.net.URLEncoder.encode("Invalid data provided for prescription.", "UTF-8"));
            }

        } catch (NumberFormatException e) {
            response.sendRedirect("TreatmentServlet?action=manage&error="
                    + java.net.URLEncoder.encode("Invalid prescription or treatment ID.", "UTF-8"));
        } catch (Exception e) {
            String treatmentId = request.getParameter("treatmentId");
            response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId + "&prescriptionError="
                    + java.net.URLEncoder.encode("Error updating prescription: " + e.getMessage(), "UTF-8"));
        }
    }

    private void handleCompleteAppointment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            String docMessage = request.getParameter("docMessage");

            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment != null && "approved".equals(appointment.getStatus())) {
                appointment.setStatus("completed");
                if (docMessage != null && !docMessage.trim().isEmpty()) {
                    appointment.setDocMessage(docMessage.trim());
                }
                appointmentFacade.edit(appointment);

                String successMessage = "Appointment completed successfully.";
                response.sendRedirect("TreatmentServlet?action=myTasks&success="
                        + java.net.URLEncoder.encode(successMessage, "UTF-8"));
            } else {
                String errorMessage = "Appointment not found or not in approved status.";
                response.sendRedirect("TreatmentServlet?action=myTasks&error="
                        + java.net.URLEncoder.encode(errorMessage, "UTF-8"));
            }
        } catch (NumberFormatException e) {
            String errorMessage = "Invalid appointment ID.";
            response.sendRedirect("TreatmentServlet?action=myTasks&error="
                    + java.net.URLEncoder.encode(errorMessage, "UTF-8"));
        } catch (Exception e) {
            e.printStackTrace();
            String errorMessage = "Error completing appointment: " + e.getMessage();
            response.sendRedirect("TreatmentServlet?action=myTasks&error="
                    + java.net.URLEncoder.encode(errorMessage, "UTF-8"));
        }
    }

    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
