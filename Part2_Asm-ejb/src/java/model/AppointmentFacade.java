/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

/**
 *
 * @author chris
 */
@Stateless
public class AppointmentFacade extends AbstractFacade<Appointment> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public AppointmentFacade() {
        super(Appointment.class);
    }

    public List<Appointment> findByCustomer(Customer customer) {
        return em.createQuery("SELECT a FROM Appointment a WHERE a.customer = :customer", Appointment.class)
                .setParameter("customer", customer)
                .getResultList();
    }

    /**
     * Find appointments for a specific doctor on a specific date
     */
    public List<Appointment> findByDoctorAndDate(int doctorId, String date) {
        Query query = em.createQuery("SELECT a FROM Appointment a WHERE a.doctor.id = :doctorId AND a.appointmentDate = :date AND a.status != 'cancelled'");
        query.setParameter("doctorId", doctorId);
        query.setParameter("date", Date.valueOf(date));
        return query.getResultList();
    }

    // find recent appointments 
    public List<Appointment> findRecentAppointments(int limit) {
        try {
            Query query = em.createQuery("SELECT a FROM Appointment a ORDER BY a.appointmentDate DESC");
            query.setMaxResults(limit);
            return query.getResultList();
        } catch (Exception e) {
            System.err.println("Error finding recent appointments: " + e.getMessage());
            return new ArrayList<>();
        }
    }
}
