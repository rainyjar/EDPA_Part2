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
@WebServlet(urlPatterns = {"/Register"})
public class Register extends HttpServlet {

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
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String role = request.getParameter("role");

            // Empty fields validation
            if (name == null || email == null || password == null || role == null
                    || name.isEmpty() || email.isEmpty() || password.isEmpty() || role.isEmpty()) {
                request.setAttribute("error", "All fields are required.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // email validation
            if (!email.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
                request.setAttribute("error", "Invalid email format.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // password validation
            if (password.length() < 6) {
                request.setAttribute("error", "Password must be at least 6 characters long.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

//            try {
//                Manager found = managerFacade.searchEmail(email);
//
//                if (found != null) {
//                    request.setAttribute("error", "Email is already registered.");
//                    request.getRequestDispatcher("register.jsp").forward(request, response);
//                    return;
//                }
//                managerFacade.create(new Manager(name, email, password));
//                request.setAttribute("success", "Registered successfully! You may login now.");
//                request.getRequestDispatcher("register.jsp").include(request, response);
////                request.getRequestDispatcher("register.jsp").include(request, response);
////                request.setAttribute("success", "Welcome again " + name + ", you may login now!!");
//
//            } catch (Exception e) {
////                request.setAttribute("error", "Invalid inputs! Please try again");
////                request.getRequestDispatcher("register.jsp").include(request, response);
////                out.println("<br><br><br>Sorry " + name + ", invalid input!");
//                System.out.print("Error:" + e);
//                request.setAttribute("error", "Server error occurred during registration. Please try again later.");
//                request.getRequestDispatcher("register.jsp").forward(request, response);
//            }
            try {
                boolean emailExists = false;

                switch (role.toLowerCase()) {
                    case "manager":
                        emailExists = managerFacade.searchEmail(email) != null;
                        if (!emailExists) {
                            managerFacade.create(new Manager(name, email, password));
                        }
                        break;
                    case "doctor":
                        emailExists = doctorFacade.searchEmail(email) != null;
                        if (!emailExists) {
                            doctorFacade.create(new Doctor(name, email, password));
                        }
                        break;
                    case "counter_staff":
                        emailExists = counterStaffFacade.searchEmail(email) != null;
                        if (!emailExists) {
                            counterStaffFacade.create(new CounterStaff(name, email, password));
                        }
                        break;
                    case "customer":
                        emailExists = customerFacade.searchEmail(email) != null;
                        if (!emailExists) {
                            customerFacade.create(new Customer(name, email, password));
                        }
                        break;
                }

                if (emailExists) {
                    request.setAttribute("error", "Email already registered for this role.");
                    request.getRequestDispatcher("register.jsp").forward(request, response);
                    return;
                }

                request.setAttribute("success", "Registered successfully! Please login.");
                request.getRequestDispatcher("register.jsp").include(request, response);
            } catch (Exception e) {
                request.setAttribute("error", "Server error: " + e.getMessage());
                request.getRequestDispatcher("register.jsp").forward(request, response);
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
