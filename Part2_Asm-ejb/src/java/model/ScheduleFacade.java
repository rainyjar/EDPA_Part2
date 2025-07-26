/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

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
public class ScheduleFacade extends AbstractFacade<Schedule> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public ScheduleFacade() {
        super(Schedule.class);
    }
    
    /**
     * Find all schedules for a specific doctor
     */
    public List<Schedule> findByDoctorId(int doctorId) {
        Query query = em.createQuery("SELECT s FROM Schedule s WHERE s.doctor.id = :doctorId");
        query.setParameter("doctorId", doctorId);
        return query.getResultList();
    }
    
    /**
     * Find schedules for a specific doctor on a specific day
     */
    public List<Schedule> findByDoctorAndDay(int doctorId, String dayOfWeek) {
        // Try both formats - exact match first, then case-insensitive
        Query query = em.createQuery("SELECT s FROM Schedule s WHERE s.doctor.id = :doctorId AND LOWER(s.dayOfWeek) = LOWER(:dayOfWeek)");
        query.setParameter("doctorId", doctorId);
        query.setParameter("dayOfWeek", dayOfWeek);
        return query.getResultList();
    }
    
}
