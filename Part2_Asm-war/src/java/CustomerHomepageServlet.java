/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import java.io.IOException;
import java.util.List;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.Doctor;
import model.DoctorFacade;
import model.Treatment;
import model.TreatmentFacade;

/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/CustomerHomepageServlet"})
public class CustomerHomepageServlet extends HttpServlet {

    @EJB
    private TreatmentFacade treatmentFacade;

    @EJB
    private DoctorFacade doctorFacade;

    /**
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code>
     * methods.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check if customer is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("customer") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        List<Doctor> doctorList = doctorFacade.findAll();
        List<Treatment> treatmentList = treatmentFacade.findAll();

        System.out.println("Doctor list size: " + (doctorList != null ? doctorList.size() : "null"));
        System.out.println("Treatment list size: " + (treatmentList != null ? treatmentList.size() : "null"));
        System.out.println("treatmentFacade is null: " + (treatmentFacade == null));
        if (treatmentList != null) {
            for (Treatment t : treatmentList) {
                System.out.println(t.getName());
            }
        }
        if (doctorList != null) {
            for (Doctor t : doctorList) {
                System.out.println(t.getName());
            }
        }

        request.setAttribute("doctorList", doctorList);
        request.setAttribute("treatmentList", treatmentList);

        request.getRequestDispatcher("customer/cust_homepage.jsp").forward(request, response);

    }

    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
