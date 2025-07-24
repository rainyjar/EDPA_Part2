/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import java.io.IOException;
import java.io.PrintWriter;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.CounterStaff;
import model.CounterStaffFacade;
import model.Customer;
import model.CustomerFacade;
import model.Doctor;
import model.DoctorFacade;
import model.Manager;
import model.ManagerFacade;

/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/Login"})
public class Login extends HttpServlet {

    @EJB
    private ManagerFacade managerFacade;

    @EJB
    private CounterStaffFacade counterStaffFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @EJB
    private CustomerFacade customerFacade;

    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");

        try (PrintWriter out = response.getWriter()) {
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String role = request.getParameter("role");

            // Empty fields validation
            if (email == null || password == null || role == null
                    || email.isEmpty() || password.isEmpty() || role.isEmpty()) {
                request.setAttribute("error", "All fields are required.");
                request.getRequestDispatcher("login.jsp").forward(request, response);
                return;
            }
            try {
                Object user = null;

                switch (role.toLowerCase()) {
                    case "manager":
                        user = managerFacade.searchEmail(email);
                        break;
                    case "doctor":
                        user = doctorFacade.searchEmail(email);
                        break;
                    case "counter_staff":
                        user = counterStaffFacade.searchEmail(email);
                        break;
                    case "customer":
                        user = customerFacade.searchEmail(email);
                        break;
                }

                if (user == null) {
                    request.setAttribute("error", "No user found with this email.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                    return;
                }

                String userPassword = null;
                if (user instanceof Manager) {
                    userPassword = ((Manager) user).getPassword();
                } else if (user instanceof Doctor) {
                    userPassword = ((Doctor) user).getPassword();
                } else if (user instanceof CounterStaff) {
                    userPassword = ((CounterStaff) user).getPassword();
                } else if (user instanceof Customer) {
                    userPassword = ((Customer) user).getPassword();
                }

                if (!password.equals(userPassword)) {
                    request.setAttribute("error", "Incorrect password.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                    return;
                }

                HttpSession s = request.getSession();
                s.setAttribute("user", user);
                s.setAttribute("role", role);

                // Set the name based on role
                if (user instanceof Manager) {
                    s.setAttribute("name", ((Manager) user).getName());
                    response.sendRedirect(role + "/dashboard.jsp");
                } else if (user instanceof Doctor) {
                    s.setAttribute("name", ((Doctor) user).getName());
                    response.sendRedirect(role + "/dashboard.jsp");
                } else if (user instanceof CounterStaff) {
                    s.setAttribute("name", ((CounterStaff) user).getName());
                    response.sendRedirect(role + "/dashboard.jsp");
                } else if (user instanceof Customer) {
//                    s.setAttribute("name", ((Customer) user).getName());
                    s.setAttribute("customer", (Customer) user);
//                    response.sendRedirect(role + "/cust_homepage.jsp");
                    response.sendRedirect("CustomerHomepageServlet");
                    System.out.print(((Customer) user).getId());
                }

            } catch (Exception e) {
                request.setAttribute("error", "Login failed: " + e.getMessage());
                request.getRequestDispatcher("login.jsp").forward(request, response);
            }
        }
    }

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /**
     * Handles the HTTP <code>GET</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Handles the HTTP <code>POST</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
