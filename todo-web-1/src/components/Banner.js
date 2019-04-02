import React from "react";
import styled from "@emotion/styled";
const Banner = props => {
  const BannerContainer = styled.div`
    grid-area: banner;
    margin: 10px;
    background: 
      url(/banner.png)
        no-repeat center;
  `;
  return <BannerContainer {...props} />;
};
export default Banner;
