/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import java.util.ArrayList;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.Query;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

/**
 *
 * @author chris
 */
@Stateless
public class PaymentFacade extends AbstractFacade<Payment> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public PaymentFacade() {
        super(Payment.class);
    }

    /**
     * Find payment by appointment ID
     */
    public Payment findByAppointmentId(int appointmentId) {
        try {
            return em.createQuery("SELECT p FROM Payment p WHERE p.appointment.id = :appointmentId", Payment.class)
                    .setParameter("appointmentId", appointmentId)
                    .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Find payments by status
     */
    public java.util.List<Payment> findByStatus(String status) {
        try {
            String orderClause;
            if ("pending".equals(status)) {
                // For pending payments, order by appointment date or ID since paymentDate is null
                orderClause = "ORDER BY p.appointment.appointmentDate DESC, p.id DESC";
            } else {
                // For paid payments, order by payment date
                orderClause = "ORDER BY p.paymentDate DESC";
            }

            return em.createQuery("SELECT p FROM Payment p WHERE p.status = :status " + orderClause, Payment.class)
                    .setParameter("status", status)
                    .getResultList();
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Error finding payments by status: " + e.getMessage());
            return new java.util.ArrayList<>();
        }
    }

    /**
     * Find payments by doctor ID and payment status
     *
     * @param doctorId The doctor's ID
     * @param status The payment status to filter by
     * @return List of payments matching the criteria
     */
    public List<Payment> findByDoctorAndStatus(int doctorId, String status) {
        try {
            // First, debug query to see ALL pending payments regardless of doctor
            System.out.println("DEBUG: Checking ALL payments with status '" + status + "'");
            List<Payment> allStatusPayments = em.createQuery(
                    "SELECT p FROM Payment p WHERE p.status = :status", Payment.class)
                    .setParameter("status", status)
                    .getResultList();

            System.out.println("DEBUG: Found " + allStatusPayments.size() + " total '" + status + "' payments");

            // Check each pending payment for doctor details
            for (Payment p : allStatusPayments) {
                Appointment apt = p.getAppointment();
                if (apt != null) {
                    Doctor doc = apt.getDoctor();
                    System.out.println("DEBUG: Payment ID " + p.getId()
                            + " for Appointment ID " + apt.getId()
                            + " has Doctor: " + (doc != null ? doc.getId() + " (" + doc.getName() + ")" : "NULL"));
                } else {
                    System.out.println("DEBUG: Payment ID " + p.getId() + " has no appointment");
                }
            }

            // Original query to find doctor-specific payments
            Query query = em.createQuery(
                    "SELECT p FROM Payment p WHERE p.appointment.doctor.id = :doctorId AND p.status = :status"
            );
            query.setParameter("doctorId", doctorId);
            query.setParameter("status", status);
            List<Payment> results = query.getResultList();
            System.out.println("DEBUG: Found " + results.size() + " payments for doctor ID " + doctorId + " with status '" + status + "'");
            return results;
        } catch (Exception e) {
            System.out.println("Error finding payments by doctor and status: " + e.getMessage());
            e.printStackTrace();
            return new ArrayList<>();
        }
    }

    /**
     * Find all payments ordered by date
     */
    @Override
    public java.util.List<Payment> findAll() {
        try {
            return em.createQuery("SELECT p FROM Payment p ORDER BY p.paymentDate DESC", Payment.class)
                    .getResultList();
        } catch (Exception e) {
            return new java.util.ArrayList<>();
        }
    }

    public double getTotalRevenue() {
        Double result = em.createQuery("SELECT SUM(p.amount) FROM Payment p WHERE p.status = 'paid'", Double.class)
                .getSingleResult();
        return result != null ? result : 0.0;
    }

}
