/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import java.io.Serializable;
import java.util.List;
import java.util.Set;
import javax.persistence.CascadeType;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.*;

/**
 *
 * @author chris
 */
@Entity
public class Treatment implements Serializable {

    private static final long serialVersionUID = 1L;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private String name, longDescription, shortDescription, treatmentPic;
    private double baseConsultationCharge, followUpCharge;

    @OneToMany(mappedBy = "treatment", cascade = CascadeType.ALL)
    private List<Prescription> prescriptions;

    @ManyToMany
    @JoinTable(
            name = "Treatment_Doctor",
            joinColumns = @JoinColumn(name = "treatment_id"),
            inverseJoinColumns = @JoinColumn(name = "doc_id")
    )
    private Set<Doctor> doctors;

    @OneToMany(mappedBy = "treatment")
    private List<Appointment> appointments;

    public Treatment() {
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getLongDescription() {
        return longDescription;
    }

    public void setLongDescription(String longDescription) {
        this.longDescription = longDescription;
    }

    public String getShortDescription() {
        return shortDescription;
    }

    public void setShortDescription(String shortDescription) {
        this.shortDescription = shortDescription;
    }

    public String getTreatmentPic() {
        return treatmentPic;
    }

    public void setTreatmentPic(String treatmentPic) {
        this.treatmentPic = treatmentPic;
    }

    public double getBaseConsultationCharge() {
        return baseConsultationCharge;
    }

    public void setBaseConsultationCharge(double baseConsultationCharge) {
        this.baseConsultationCharge = baseConsultationCharge;
    }

    public double getFollowUpCharge() {
        return followUpCharge;
    }

    public void setFollowUpCharge(double followUpCharge) {
        this.followUpCharge = followUpCharge;
    }

    public List<Prescription> getPrescriptions() {
        return prescriptions;
    }

    public void setPrescriptions(List<Prescription> prescriptions) {
        this.prescriptions = prescriptions;
    }

    public Set<Doctor> getDoctors() {
        return doctors;
    }

    public void setDoctors(Set<Doctor> doctors) {
        this.doctors = doctors;
    }

    public List<Appointment> getAppointments() {
        return appointments;
    }

    public void setAppointments(List<Appointment> appointments) {
        this.appointments = appointments;
    }

        @Override
    public int hashCode() {
        int hash = 0;
        hash += (int) id;
        return hash;
    }

    @Override
    public boolean equals(Object object) {
        // TODO: Warning - this method won't work in the case the id fields are not set
        if (!(object instanceof Receipt)) {
            return false;
        }
        Treatment other = (Treatment) object;
        if (this.id != other.id) {
            return false;
        }
        return true;
    }

    @Override
    public String toString() {
        return "model.Treatment[ id=" + id + " ]";
    }

}
