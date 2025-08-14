import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.Doctor;
import model.Prescription;
import model.PrescriptionFacade;
import model.Treatment;
import model.TreatmentFacade;

@WebServlet(urlPatterns = {"/TreatmentServlet"})
public class TreatmentServlet extends HttpServlet {

    @EJB
    private PrescriptionFacade prescriptionFacade;

    @EJB
    private TreatmentFacade treatmentFacade;

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
            request.getRequestDispatcher("/customer/treatment.jsp").forward(request, response);

        } else if ("viewDetail".equalsIgnoreCase(action) && idParam != null) {
            try {
                int id = Integer.parseInt(idParam);
                Treatment treatment = treatmentFacade.find(id);
                List<Prescription> prescriptions = prescriptionFacade.findByTreatmentId(id);
                request.setAttribute("treatment", treatment);
                request.setAttribute("prescriptions", prescriptions);
                request.getRequestDispatcher("/customer/treatment_description.jsp").forward(request, response);
            } catch (NumberFormatException e) {
                request.setAttribute("error", "Invalid treatment ID.");
                request.getRequestDispatcher("/customer/treatment.jsp").forward(request, response);
            }

        } else if ("manage".equalsIgnoreCase(action)) {
            // Doctor management page - show all treatments with CRUD options
            if (loggedInDoctor == null) {
                response.sendRedirect("login.jsp");
                return;
            }
            List<Treatment> treatmentList = treatmentFacade.findAll();
            request.setAttribute("treatmentList", treatmentList);
            request.getRequestDispatcher("/doctor/manage_treatments.jsp").forward(request, response);

        } else if ("createForm".equalsIgnoreCase(action)) {
            // Show form to create new treatment
            if (loggedInDoctor == null) {
                response.sendRedirect("login.jsp");
                return;
            }
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
                request.setAttribute("treatment", treatment);
                request.setAttribute("prescriptions", prescriptions);
                request.getRequestDispatcher("/doctor/edit_treatment.jsp").forward(request, response);
            } catch (NumberFormatException e) {
                request.setAttribute("error", "Invalid treatment ID.");
                response.sendRedirect("TreatmentServlet?action=manage");
            }

        } else if ("deletePrescription".equalsIgnoreCase(action)) {
            // Delete a prescription
            if (loggedInDoctor == null) {
                response.sendRedirect("login.jsp");
                return;
            }
            String prescriptionIdParam = request.getParameter("prescriptionId");
            String treatmentIdParam = request.getParameter("treatmentId");
            
            if (prescriptionIdParam != null && treatmentIdParam != null) {
                try {
                    int prescriptionId = Integer.parseInt(prescriptionIdParam);
                    Prescription prescription = prescriptionFacade.find(prescriptionId);
                    if (prescription != null) {
                        prescriptionFacade.remove(prescription);
                        request.setAttribute("success", "Prescription deleted successfully.");
                    }
                    response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentIdParam);
                } catch (NumberFormatException e) {
                    request.setAttribute("error", "Invalid prescription ID.");
                    response.sendRedirect("TreatmentServlet?action=manage");
                }
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

        } else {
            response.sendRedirect("TreatmentServlet?action=manage");
        }
    }

    private void handleCreateTreatment(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        try {
            // Create new treatment
            Treatment treatment = new Treatment();
            treatment.setName(request.getParameter("name"));
            treatment.setShortDescription(request.getParameter("shortDesc"));
            treatment.setLongDescription(request.getParameter("longDesc"));
            treatment.setBaseConsultationCharge(Double.parseDouble(request.getParameter("baseCharge")));
            treatment.setFollowUpCharge(Double.parseDouble(request.getParameter("followUpCharge")));
            treatment.setTreatmentPic(request.getParameter("treatmentPic"));

            treatmentFacade.create(treatment);

            // Handle prescriptions if provided
            String[] conditionNames = request.getParameterValues("conditionName");
            String[] medicationNames = request.getParameterValues("medicationName");

            if (conditionNames != null && medicationNames != null) {
                for (int i = 0; i < Math.min(conditionNames.length, medicationNames.length); i++) {
                    if (conditionNames[i] != null && !conditionNames[i].trim().isEmpty() &&
                        medicationNames[i] != null && !medicationNames[i].trim().isEmpty()) {
                        
                        Prescription prescription = new Prescription();
                        prescription.setConditionName(conditionNames[i].trim());
                        prescription.setMedicationName(medicationNames[i].trim());
                        prescription.setTreatment(treatment);
                        
                        prescriptionFacade.create(prescription);
                    }
                }
            }

            request.setAttribute("success", "Treatment created successfully with prescriptions.");
            response.sendRedirect("TreatmentServlet?action=manage");

        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid numeric values provided.");
            request.getRequestDispatcher("/doctor/create_treatment.jsp").forward(request, response);
        } catch (Exception e) {
            request.setAttribute("error", "Error creating treatment: " + e.getMessage());
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
                treatment.setTreatmentPic(request.getParameter("treatmentPic"));

                treatmentFacade.edit(treatment);

                // Handle new prescriptions if provided
                String[] conditionNames = request.getParameterValues("conditionName");
                String[] medicationNames = request.getParameterValues("medicationName");

                if (conditionNames != null && medicationNames != null) {
                    for (int i = 0; i < Math.min(conditionNames.length, medicationNames.length); i++) {
                        if (conditionNames[i] != null && !conditionNames[i].trim().isEmpty() &&
                            medicationNames[i] != null && !medicationNames[i].trim().isEmpty()) {
                            
                            Prescription prescription = new Prescription();
                            prescription.setConditionName(conditionNames[i].trim());
                            prescription.setMedicationName(medicationNames[i].trim());
                            prescription.setTreatment(treatment);
                            
                            prescriptionFacade.create(prescription);
                        }
                    }
                }

                request.setAttribute("success", "Treatment updated successfully.");
            } else {
                request.setAttribute("error", "Treatment not found.");
            }
            
            response.sendRedirect("TreatmentServlet?action=editForm&id=" + id);

        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid treatment ID or numeric values.");
            response.sendRedirect("TreatmentServlet?action=manage");
        } catch (Exception e) {
            request.setAttribute("error", "Error updating treatment: " + e.getMessage());
            response.sendRedirect("TreatmentServlet?action=manage");
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
            
            if (treatment != null && conditionName != null && !conditionName.trim().isEmpty() &&
                medicationName != null && !medicationName.trim().isEmpty()) {
                
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
            
            if (prescription != null && conditionName != null && !conditionName.trim().isEmpty() &&
                medicationName != null && !medicationName.trim().isEmpty()) {
                
                prescription.setConditionName(conditionName.trim());
                prescription.setMedicationName(medicationName.trim());
                
                prescriptionFacade.edit(prescription);
                request.setAttribute("success", "Prescription updated successfully.");
            } else {
                request.setAttribute("error", "Invalid data provided for prescription.");
            }
            
            response.sendRedirect("TreatmentServlet?action=editForm&id=" + treatmentId);
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid prescription or treatment ID.");
            response.sendRedirect("TreatmentServlet?action=manage");
        } catch (Exception e) {
            request.setAttribute("error", "Error updating prescription: " + e.getMessage());
            response.sendRedirect("TreatmentServlet?action=manage");
        }
    }

    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
