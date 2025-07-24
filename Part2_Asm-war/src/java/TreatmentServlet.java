/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.Prescription;
import model.PrescriptionFacade;
import model.Treatment;
import model.TreatmentFacade;

/**
 *
 * @author chris
 */
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

        } else if ("editForm".equalsIgnoreCase(action) && idParam != null) {
            int id = Integer.parseInt(idParam);
            Treatment treatment = treatmentFacade.find(id);
            request.setAttribute("treatment", treatment);
            request.getRequestDispatcher("/admin/edit_treatment.jsp").forward(request, response); // for example
        } else {
            response.sendRedirect("error.jsp"); // or handle unknown action
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");

        if ("create".equalsIgnoreCase(action)) {
            // Read form data
            Treatment t = new Treatment();
            t.setName(request.getParameter("name"));
            t.setShortDescription(request.getParameter("shortDesc"));
            t.setLongDescription(request.getParameter("longDesc"));
            t.setBaseConsultationCharge(Double.parseDouble(request.getParameter("baseCharge")));
            t.setFollowUpCharge(Double.parseDouble(request.getParameter("followUpCharge")));
            t.setTreatmentPic(request.getParameter("treatmentPic")); // Assuming filename or path

            treatmentFacade.create(t);
            response.sendRedirect("TreatmentServlet?action=viewAll");

        } else if ("update".equalsIgnoreCase(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Treatment t = treatmentFacade.find(id);
            if (t != null) {
                t.setName(request.getParameter("name"));
                t.setShortDescription(request.getParameter("shortDesc"));
                t.setLongDescription(request.getParameter("longDesc"));
                t.setBaseConsultationCharge(Double.parseDouble(request.getParameter("baseCharge")));
                t.setFollowUpCharge(Double.parseDouble(request.getParameter("followUpCharge")));
                t.setTreatmentPic(request.getParameter("treatmentPic"));

                treatmentFacade.edit(t);
            }
            response.sendRedirect("TreatmentServlet?action=viewAll");

        } else if ("delete".equalsIgnoreCase(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Treatment t = treatmentFacade.find(id);
            if (t != null) {
                treatmentFacade.remove(t);
            }
            response.sendRedirect("TreatmentServlet?action=viewAll");
        }
    }

    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
