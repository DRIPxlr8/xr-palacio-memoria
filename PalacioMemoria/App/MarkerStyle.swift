/// Aspecto con que la cámara muestra un marcador cuando no va con su color normal.
/// Lo decide el estado de la app; la capa AR elige el color de cada caso.
public enum MarkerStyle {
    /// Marcador del término abierto en el panel.
    case selected
    /// Término respondido como «Acerté» en el quiz.
    case correct
    /// Término respondido como «No acerté» en el quiz.
    case incorrect
}
